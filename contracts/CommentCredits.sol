// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title CommentCredits
 * @dev Smart contract for managing comment credits and storing comments on-chain
 * @notice Users purchase credits with KAS, then use credits to submit comments
 */
contract CommentCredits is Ownable, ReentrancyGuard {
    // Credit structure
    struct CreditBalance {
        uint256 creditsRemaining;
        uint256 totalPurchased;
        bool hasUnlimitedCredits; // For 100M+ KREX holders
        uint256 lastPurchaseDate;
    }

    // Comment structure
    struct Comment {
        uint256 id;
        string articleId; // Can be article ID or dApp ID/slug
        address author;
        string content;
        uint256 timestamp;
        uint256 parentCommentId; // 0 if top-level comment
        bool deleted;
    }

    // Credit balances per user
    mapping(address => CreditBalance) public creditBalances;
    
    // Comments storage
    mapping(uint256 => Comment) public comments;
    mapping(string => uint256[]) public commentsByArticle; // articleId => comment IDs
    
    // Comment counter
    uint256 public commentCounter;
    
    // Pricing
    uint256 public constant BASE_CREDITS_PER_KAS = 1; // 1 credit per KAS (base rate)
    uint256 public constant KREX_UNLIMITED_THRESHOLD = 100_000_000 * 1e8; // 100M KREX (assuming 8 decimals)
    
    // KREX token address (to check balance for unlimited credits)
    address public krexTokenAddress;
    
    // Events
    event CreditsPurchased(
        address indexed user,
        uint256 credits,
        uint256 kasAmount,
        uint256 timestamp
    );
    
    event CreditUsed(
        address indexed user,
        uint256 creditsRemaining,
        uint256 timestamp
    );
    
    event CommentSubmitted(
        uint256 indexed commentId,
        string indexed articleId,
        address indexed author,
        string content,
        uint256 timestamp,
        uint256 parentCommentId
    );
    
    event CommentDeleted(
        uint256 indexed commentId,
        address indexed author,
        uint256 timestamp
    );
    
    event UnlimitedCreditsGranted(
        address indexed user,
        uint256 timestamp
    );
    
    event KREXTokenAddressUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Constructor
     * @param _krexTokenAddress Address of KREX token contract (for unlimited credits check)
     */
    constructor(address _krexTokenAddress) Ownable(msg.sender) {
        krexTokenAddress = _krexTokenAddress;
        commentCounter = 0;
    }

    /**
     * @dev Purchase comment credits
     * @notice Users send KAS to purchase credits (1 KAS = 1 credit base rate)
     */
    function purchaseCredits() external payable nonReentrant {
        require(msg.value > 0, "CommentCredits: Must send KAS to purchase credits");
        
        uint256 creditsToAdd = msg.value / 1e8; // Convert KAS (assuming 8 decimals) to credits
        require(creditsToAdd > 0, "CommentCredits: Amount too small");
        
        CreditBalance storage balance = creditBalances[msg.sender];
        balance.creditsRemaining += creditsToAdd;
        balance.totalPurchased += creditsToAdd;
        balance.lastPurchaseDate = block.timestamp;
        
        emit CreditsPurchased(msg.sender, creditsToAdd, msg.value, block.timestamp);
    }

    /**
     * @dev Submit a comment (requires credits)
     * @param _articleId Article ID or dApp ID/slug
     * @param _content Comment content (stored fully on-chain)
     * @param _parentCommentId Parent comment ID (0 for top-level comments)
     * @return commentId The ID of the created comment
     */
    function submitComment(
        string memory _articleId,
        string memory _content,
        uint256 _parentCommentId
    ) external nonReentrant returns (uint256) {
        require(bytes(_content).length > 0, "CommentCredits: Comment cannot be empty");
        require(bytes(_articleId).length > 0, "CommentCredits: Article ID cannot be empty");
        
        CreditBalance storage balance = creditBalances[msg.sender];
        
        // Check if user has unlimited credits (100M+ KREX)
        if (!balance.hasUnlimitedCredits) {
            // Check KREX balance if token address is set
            if (krexTokenAddress != address(0)) {
                // TODO: Implement KREX balance check via ERC20 interface
                // For now, unlimited credits must be set manually by owner
            }
            
            // Check if user has credits
            require(balance.creditsRemaining > 0, "CommentCredits: Insufficient credits");
            
            // Deduct credit
            balance.creditsRemaining -= 1;
            emit CreditUsed(msg.sender, balance.creditsRemaining, block.timestamp);
        }
        
        // Create comment
        commentCounter++;
        Comment memory newComment = Comment({
            id: commentCounter,
            articleId: _articleId,
            author: msg.sender,
            content: _content,
            timestamp: block.timestamp,
            parentCommentId: _parentCommentId,
            deleted: false
        });
        
        comments[commentCounter] = newComment;
        commentsByArticle[_articleId].push(commentCounter);
        
        emit CommentSubmitted(
            commentCounter,
            _articleId,
            msg.sender,
            _content,
            block.timestamp,
            _parentCommentId
        );
        
        return commentCounter;
    }

    /**
     * @dev Delete a comment (does NOT remove from chain, does NOT refund credits)
     * @param _commentId ID of the comment to delete
     */
    function deleteComment(uint256 _commentId) external nonReentrant {
        Comment storage comment = comments[_commentId];
        require(comment.id > 0, "CommentCredits: Comment does not exist");
        require(comment.author == msg.sender, "CommentCredits: Not authorized");
        require(!comment.deleted, "CommentCredits: Comment already deleted");
        
        comment.deleted = true;
        
        emit CommentDeleted(_commentId, msg.sender, block.timestamp);
    }

    /**
     * @dev Get comment by ID
     * @param _commentId Comment ID
     * @return Comment struct
     */
    function getComment(uint256 _commentId) external view returns (Comment memory) {
        return comments[_commentId];
    }

    /**
     * @dev Get all comment IDs for an article
     * @param _articleId Article ID or dApp ID/slug
     * @return Array of comment IDs
     */
    function getCommentIdsByArticle(string memory _articleId) external view returns (uint256[] memory) {
        return commentsByArticle[_articleId];
    }

    /**
     * @dev Get multiple comments by IDs
     * @param _commentIds Array of comment IDs
     * @return Array of Comment structs
     */
    function getComments(uint256[] memory _commentIds) external view returns (Comment[] memory) {
        Comment[] memory result = new Comment[](_commentIds.length);
        for (uint256 i = 0; i < _commentIds.length; i++) {
            result[i] = comments[_commentIds[i]];
        }
        return result;
    }

    /**
     * @dev Get credit balance for a user
     * @param _user User address
     * @return CreditBalance struct
     */
    function getCreditBalance(address _user) external view returns (CreditBalance memory) {
        return creditBalances[_user];
    }

    /**
     * @dev Grant unlimited credits to a user (for 100M+ KREX holders)
     * @param _user User address
     */
    function grantUnlimitedCredits(address _user) external onlyOwner {
        require(_user != address(0), "CommentCredits: Invalid user");
        creditBalances[_user].hasUnlimitedCredits = true;
        emit UnlimitedCreditsGranted(_user, block.timestamp);
    }

    /**
     * @dev Revoke unlimited credits from a user
     * @param _user User address
     */
    function revokeUnlimitedCredits(address _user) external onlyOwner {
        require(_user != address(0), "CommentCredits: Invalid user");
        creditBalances[_user].hasUnlimitedCredits = false;
    }

    /**
     * @dev Update KREX token address
     * @param _newAddress New KREX token address
     */
    function setKREXTokenAddress(address _newAddress) external onlyOwner {
        address oldAddress = krexTokenAddress;
        krexTokenAddress = _newAddress;
        emit KREXTokenAddressUpdated(oldAddress, _newAddress);
    }

    /**
     * @dev Withdraw collected KAS (for contract owner)
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "CommentCredits: No funds to withdraw");
        payable(owner()).transfer(balance);
    }

    /**
     * @dev Receive function to accept KAS payments
     */
    receive() external payable {
        // Allow direct KAS transfers for credit purchases
        if (msg.value > 0) {
            purchaseCredits();
        }
    }
}

