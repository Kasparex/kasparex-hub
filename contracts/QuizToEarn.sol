// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./FeeCollector.sol";
import "./ProofOfUtility.sol";

/**
 * @title QuizToEarn
 * @dev Quiz game where users answer questions to earn rewards
 * @notice Users answer crypto/ecosystem questions and earn GRID or token rewards for correct answers
 */
contract QuizToEarn is Ownable, ReentrancyGuard {
    FeeCollector public feeCollector;
    ProofOfUtility public proofOfUtility;
    uint256 public dAppId; // To be set by DAppRegistry after registration
    
    // Default fee configuration (1% = 100 basis points)
    uint256 public feePercentage = 100; // 1% default fee
    uint256 public constant BASIS_POINTS = 10000; // 100% = 10000 basis points
    
    // Quiz question structure
    struct Question {
        uint256 id;
        string questionText;
        string[] options; // Array of answer options
        uint256 correctAnswerIndex; // Index of correct answer (0-based)
        string category; // e.g., "Kaspa", "BlockDAG", "General"
        uint256 rewardAmount; // Reward amount in wei for correct answer
        bool isActive; // Whether question is active
        uint256 createdAt;
    }
    
    // User answer tracking
    struct UserAnswer {
        uint256 questionId;
        uint256 selectedAnswerIndex;
        bool isCorrect;
        uint256 timestamp;
        bool rewardClaimed;
    }
    
    // State variables
    mapping(uint256 => Question) public questions;
    mapping(address => mapping(uint256 => UserAnswer)) public userAnswers; // user => questionId => answer
    mapping(address => uint256[]) public userAnsweredQuestions; // user => array of question IDs
    uint256 public questionCount;
    uint256 public defaultRewardAmount; // Default reward value per correct answer (used for RewardManager calculation, represents token value, not KAS)
    
    // Events
    event QuestionAdded(
        uint256 indexed questionId,
        string questionText,
        string category,
        uint256 rewardAmount,
        uint256 timestamp
    );
    event QuestionUpdated(uint256 indexed questionId, bool isActive);
    event AnswerSubmitted(
        address indexed user,
        uint256 indexed questionId,
        uint256 selectedAnswerIndex,
        bool isCorrect,
        uint256 rewardAmount,
        uint256 timestamp
    );
    event RewardClaimed(
        address indexed user,
        uint256 indexed questionId,
        uint256 rewardAmount,
        uint256 timestamp
    );
    event DAppInitialized(uint256 indexed dAppId, address indexed deployer, uint256 timestamp);
    event DefaultRewardUpdated(uint256 oldReward, uint256 newReward);
    
    /**
     * @dev Constructor
     * @param _feeCollector Address of the FeeCollector contract
     * @param _proofOfUtility Address of the ProofOfUtility contract
     * @param _feePercentage Initial fee percentage in basis points (default: 100 = 1%)
     * @param _defaultRewardAmount Default reward value per correct answer (used for RewardManager calculation, represents token value, not KAS)
     */
    constructor(
        address _feeCollector,
        address _proofOfUtility,
        uint256 _feePercentage,
        uint256 _defaultRewardAmount
    ) Ownable(msg.sender) {
        require(_feeCollector != address(0), "QuizToEarn: Invalid fee collector");
        require(_proofOfUtility != address(0), "QuizToEarn: Invalid ProofOfUtility");
        require(_feePercentage <= BASIS_POINTS, "QuizToEarn: Fee percentage too high");
        
        feeCollector = FeeCollector(_feeCollector);
        proofOfUtility = ProofOfUtility(_proofOfUtility);
        feePercentage = _feePercentage == 0 ? 100 : _feePercentage; // Default to 1% if not provided
        defaultRewardAmount = _defaultRewardAmount;
    }
    
    /**
     * @dev Sets the dApp ID after registration in the DAppRegistry.
     *      This function can only be called once by the owner.
     * @param _dAppId The ID assigned by the DAppRegistry.
     */
    function setDAppId(uint256 _dAppId) external onlyOwner {
        require(dAppId == 0, "QuizToEarn: dApp ID already set");
        require(_dAppId > 0, "QuizToEarn: Invalid dApp ID");
        dAppId = _dAppId;
        emit DAppInitialized(dAppId, msg.sender, block.timestamp);
    }
    
    /**
     * @dev Add a new quiz question (admin only)
     * @param _questionText The question text
     * @param _options Array of answer options
     * @param _correctAnswerIndex Index of the correct answer (0-based)
     * @param _category Category of the question (e.g., "Kaspa", "BlockDAG")
     * @param _rewardAmount Reward value for correct answer (used for RewardManager calculation, represents token value, not KAS. 0 = use default)
     */
    function addQuestion(
        string memory _questionText,
        string[] memory _options,
        uint256 _correctAnswerIndex,
        string memory _category,
        uint256 _rewardAmount
    ) external onlyOwner {
        require(bytes(_questionText).length > 0, "QuizToEarn: Question text cannot be empty");
        require(_options.length >= 2, "QuizToEarn: Must have at least 2 options");
        require(_correctAnswerIndex < _options.length, "QuizToEarn: Invalid correct answer index");
        
        questionCount++;
        uint256 rewardAmount = _rewardAmount == 0 ? defaultRewardAmount : _rewardAmount;
        
        questions[questionCount] = Question({
            id: questionCount,
            questionText: _questionText,
            options: _options,
            correctAnswerIndex: _correctAnswerIndex,
            category: _category,
            rewardAmount: rewardAmount,
            isActive: true,
            createdAt: block.timestamp
        });
        
        emit QuestionAdded(questionCount, _questionText, _category, rewardAmount, block.timestamp);
    }
    
    /**
     * @dev Update question active status (admin only)
     * @param _questionId Question ID
     * @param _isActive Whether question is active
     */
    function updateQuestionStatus(uint256 _questionId, bool _isActive) external onlyOwner {
        require(_questionId > 0 && _questionId <= questionCount, "QuizToEarn: Invalid question ID");
        questions[_questionId].isActive = _isActive;
        emit QuestionUpdated(_questionId, _isActive);
    }
    
    /**
     * @dev Submit an answer to a question
     * @param _questionId Question ID
     * @param _selectedAnswerIndex Selected answer index (0-based)
     */
    function submitAnswer(uint256 _questionId, uint256 _selectedAnswerIndex) external nonReentrant {
        require(_questionId > 0 && _questionId <= questionCount, "QuizToEarn: Invalid question ID");
        Question storage question = questions[_questionId];
        require(question.isActive, "QuizToEarn: Question is not active");
        require(_selectedAnswerIndex < question.options.length, "QuizToEarn: Invalid answer index");
        require(
            userAnswers[msg.sender][_questionId].timestamp == 0,
            "QuizToEarn: Question already answered"
        );
        
        bool isCorrect = _selectedAnswerIndex == question.correctAnswerIndex;
        
        userAnswers[msg.sender][_questionId] = UserAnswer({
            questionId: _questionId,
            selectedAnswerIndex: _selectedAnswerIndex,
            isCorrect: isCorrect,
            timestamp: block.timestamp,
            rewardClaimed: false
        });
        
        userAnsweredQuestions[msg.sender].push(_questionId);
        
        // Record usage event and distribute reward via ProofOfUtility
        // Only distribute rewards for correct answers
        if (dAppId > 0 && isCorrect) {
            // Use rewardAmount as actionValue (represents value in token terms, not KAS)
            // RewardManager will calculate actual token reward: actionValue × rewardRate
            proofOfUtility.recordUsageAndReward(
                msg.sender,
                address(this),
                dAppId,
                "quiz_correct_answer",
                question.rewardAmount // This represents the value, RewardManager calculates token amount
            );
        } else if (dAppId > 0) {
            // Record wrong answer without reward
            proofOfUtility.recordUsage(
                msg.sender,
                address(this),
                dAppId,
                "quiz_wrong_answer"
            );
        }
        
        emit AnswerSubmitted(
            msg.sender,
            _questionId,
            _selectedAnswerIndex,
            isCorrect,
            isCorrect ? question.rewardAmount : 0,
            block.timestamp
        );
    }
    
    /**
     * @dev Get a question by ID
     * @param _questionId Question ID
     * @return id Question ID
     * @return questionText Question text
     * @return options Array of answer options
     * @return category Question category
     * @return rewardAmount Reward amount for correct answer
     * @return isActive Whether question is active
     * @return createdAt Creation timestamp
     */
    function getQuestion(uint256 _questionId) external view returns (
        uint256 id,
        string memory questionText,
        string[] memory options,
        string memory category,
        uint256 rewardAmount,
        bool isActive,
        uint256 createdAt
    ) {
        require(_questionId > 0 && _questionId <= questionCount, "QuizToEarn: Invalid question ID");
        Question storage q = questions[_questionId];
        return (
            q.id,
            q.questionText,
            q.options,
            q.category,
            q.rewardAmount,
            q.isActive,
            q.createdAt
        );
    }
    
    /**
     * @dev Get user's answer for a question
     * @param _user User address
     * @param _questionId Question ID
     * @return UserAnswer struct
     */
    function getUserAnswer(address _user, uint256 _questionId) external view returns (UserAnswer memory) {
        return userAnswers[_user][_questionId];
    }
    
    /**
     * @dev Get all question IDs answered by a user
     * @param _user User address
     * @return Array of question IDs
     */
    function getUserAnsweredQuestions(address _user) external view returns (uint256[] memory) {
        return userAnsweredQuestions[_user];
    }
    
    /**
     * @dev Get paginated active questions
     * @param _offset Starting index
     * @param _limit Number of questions to return
     * @return ids Array of question IDs
     * @return questionTexts Array of question texts
     * @return optionsArray Array of options arrays
     * @return categories Array of categories
     * @return rewardAmounts Array of reward amounts
     */
    function getActiveQuestions(uint256 _offset, uint256 _limit) external view returns (
        uint256[] memory ids,
        string[] memory questionTexts,
        string[][] memory optionsArray,
        string[] memory categories,
        uint256[] memory rewardAmounts
    ) {
        require(_limit > 0 && _limit <= 50, "QuizToEarn: Invalid limit");
        
        uint256 count = 0;
        uint256[] memory tempIds = new uint256[](_limit);
        string[] memory tempTexts = new string[](_limit);
        string[][] memory tempOptions = new string[][](_limit);
        string[] memory tempCategories = new string[](_limit);
        uint256[] memory tempRewards = new uint256[](_limit);
        
        for (uint256 i = _offset + 1; i <= questionCount && count < _limit; i++) {
            if (questions[i].isActive) {
                tempIds[count] = questions[i].id;
                tempTexts[count] = questions[i].questionText;
                tempOptions[count] = questions[i].options;
                tempCategories[count] = questions[i].category;
                tempRewards[count] = questions[i].rewardAmount;
                count++;
            }
        }
        
        // Resize arrays to actual count
        uint256[] memory finalIds = new uint256[](count);
        string[] memory finalTexts = new string[](count);
        string[][] memory finalOptions = new string[][](count);
        string[] memory finalCategories = new string[](count);
        uint256[] memory finalRewards = new uint256[](count);
        
        for (uint256 i = 0; i < count; i++) {
            finalIds[i] = tempIds[i];
            finalTexts[i] = tempTexts[i];
            finalOptions[i] = tempOptions[i];
            finalCategories[i] = tempCategories[i];
            finalRewards[i] = tempRewards[i];
        }
        
        return (finalIds, finalTexts, finalOptions, finalCategories, finalRewards);
    }
    
    /**
     * @dev Update default reward amount (admin only)
     * @param _newRewardAmount New default reward value (used for RewardManager calculation, represents token value, not KAS)
     */
    function setDefaultRewardAmount(uint256 _newRewardAmount) external onlyOwner {
        uint256 oldReward = defaultRewardAmount;
        defaultRewardAmount = _newRewardAmount;
        emit DefaultRewardUpdated(oldReward, _newRewardAmount);
    }
    
    /**
     * @dev Admin function - Update fee percentage (admin only)
     * @param _newFeePercentage New fee percentage in basis points (e.g., 100 = 1%)
     */
    function setFeePercentage(uint256 _newFeePercentage) external onlyOwner {
        require(_newFeePercentage <= BASIS_POINTS, "QuizToEarn: Fee percentage too high");
        feePercentage = _newFeePercentage;
    }
    
    /**
     * @dev Calculate fee for a given amount
     * @param _amount Amount to calculate fee for
     * @return Fee amount in wei
     */
    function calculateFee(uint256 _amount) public view returns (uint256) {
        return (_amount * feePercentage) / BASIS_POINTS;
    }
    
    /**
     * @dev Admin function - Update fee collector (admin only)
     * @param _feeCollector New fee collector address
     */
    function setFeeCollector(address _feeCollector) external onlyOwner {
        require(_feeCollector != address(0), "QuizToEarn: Invalid fee collector");
        feeCollector = FeeCollector(_feeCollector);
    }
    
    /**
     * @dev Admin function - Update ProofOfUtility (admin only)
     * @param _proofOfUtility New ProofOfUtility address
     */
    function setProofOfUtility(address _proofOfUtility) external onlyOwner {
        require(_proofOfUtility != address(0), "QuizToEarn: Invalid ProofOfUtility");
        proofOfUtility = ProofOfUtility(_proofOfUtility);
    }
}

