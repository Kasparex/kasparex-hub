// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./FeeCollector.sol";

/**
 * @title DAOVoting
 * @dev DAO Voting contract for submitting and voting on dApp proposals
 * @notice Allows users to submit proposals with a fee and vote on them
 */
contract DAOVoting is Ownable, ReentrancyGuard {
    // Fee collector contract
    FeeCollector public feeCollector;

    // Vote struct to track user votes
    struct Vote {
        bool support; // true = yes, false = no
        uint256 timestamp;
    }

    // Proposal struct
    struct Proposal {
        uint256 id;
        string title;
        string description;
        address proposer;
        uint256 submissionFee;
        uint256 voteFee;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 createdAt;
        bool isFlagged;
        bool isActive;
    }

    // State variables
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => Vote)) public votes; // proposalId => voter => vote
    uint256 public proposalCount;
    uint256 public submissionFee; // Fee to submit proposal (10 KAS)
    uint256 public voteFee; // Fee per vote (1 KAS)
    uint256 public flagThreshold; // Vote threshold to auto-flag (e.g., 50 votes)

    // Events
    event ProposalSubmitted(
        uint256 indexed proposalId,
        address indexed proposer,
        string title,
        uint256 timestamp
    );
    event VoteCast(
        uint256 indexed proposalId,
        address indexed voter,
        bool support,
        uint256 timestamp
    );
    event VoteChanged(
        uint256 indexed proposalId,
        address indexed voter,
        bool oldSupport,
        bool newSupport,
        uint256 timestamp
    );
    event ProposalFlagged(
        uint256 indexed proposalId,
        uint256 yesVotes,
        uint256 noVotes,
        uint256 timestamp
    );
    event SubmissionFeeUpdated(uint256 oldFee, uint256 newFee);
    event VoteFeeUpdated(uint256 oldFee, uint256 newFee);
    event FlagThresholdUpdated(uint256 oldThreshold, uint256 newThreshold);
    event FeeCollectorUpdated(address indexed oldCollector, address indexed newCollector);

    /**
     * @dev Constructor sets fee collector and initial fees
     * @param _feeCollector Address of the FeeCollector contract
     * @param _submissionFee Initial submission fee (10 KAS = 10 * 10^18)
     * @param _voteFee Initial vote fee (1 KAS = 1 * 10^18)
     * @param _flagThreshold Initial flag threshold (e.g., 50 votes)
     */
    constructor(
        address _feeCollector,
        uint256 _submissionFee,
        uint256 _voteFee,
        uint256 _flagThreshold
    ) Ownable(msg.sender) {
        require(_feeCollector != address(0), "DAOVoting: Invalid fee collector");
        feeCollector = FeeCollector(_feeCollector);
        submissionFee = _submissionFee;
        voteFee = _voteFee;
        flagThreshold = _flagThreshold;
    }

    /**
     * @dev Submit a new proposal
     * @param _title Proposal title
     * @param _description Proposal description
     * @notice Requires payment of submissionFee (10 KAS)
     */
    function submitProposal(
        string memory _title,
        string memory _description
    ) external payable nonReentrant {
        require(msg.value == submissionFee, "DAOVoting: Incorrect submission fee");
        require(bytes(_title).length > 0, "DAOVoting: Title cannot be empty");
        require(bytes(_title).length <= 200, "DAOVoting: Title too long");
        require(bytes(_description).length > 0, "DAOVoting: Description cannot be empty");
        require(bytes(_description).length <= 2000, "DAOVoting: Description too long");

        // Forward fee to treasury
        feeCollector.forwardFee{value: submissionFee}();

        // Create proposal
        proposalCount++;
        uint256 proposalId = proposalCount;

        proposals[proposalId] = Proposal({
            id: proposalId,
            title: _title,
            description: _description,
            proposer: msg.sender,
            submissionFee: submissionFee,
            voteFee: voteFee,
            yesVotes: 0,
            noVotes: 0,
            createdAt: block.timestamp,
            isFlagged: false,
            isActive: true
        });

        emit ProposalSubmitted(proposalId, msg.sender, _title, block.timestamp);
    }

    /**
     * @dev Vote on a proposal
     * @param _proposalId ID of the proposal
     * @param _support true for yes, false for no
     * @notice Requires payment of voteFee (1 KAS)
     */
    function vote(uint256 _proposalId, bool _support) external payable nonReentrant {
        require(_proposalId > 0 && _proposalId <= proposalCount, "DAOVoting: Invalid proposal ID");
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.isActive, "DAOVoting: Proposal is not active");
        require(msg.value == voteFee, "DAOVoting: Incorrect vote fee");

        // Check if user has already voted
        Vote memory existingVote = votes[_proposalId][msg.sender];
        require(existingVote.timestamp == 0, "DAOVoting: Already voted, use changeVote");

        // Forward fee to treasury
        feeCollector.forwardFee{value: voteFee}();

        // Record vote
        votes[_proposalId][msg.sender] = Vote({
            support: _support,
            timestamp: block.timestamp
        });

        // Update vote counts
        if (_support) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }

        emit VoteCast(_proposalId, msg.sender, _support, block.timestamp);

        // Auto-flag if threshold reached
        if (proposal.yesVotes >= flagThreshold && !proposal.isFlagged) {
            proposal.isFlagged = true;
            emit ProposalFlagged(_proposalId, proposal.yesVotes, proposal.noVotes, block.timestamp);
        }
    }

    /**
     * @dev Change an existing vote
     * @param _proposalId ID of the proposal
     * @param _newSupport New vote (true for yes, false for no)
     * @notice Requires payment of voteFee (1 KAS)
     */
    function changeVote(uint256 _proposalId, bool _newSupport) external payable nonReentrant {
        require(_proposalId > 0 && _proposalId <= proposalCount, "DAOVoting: Invalid proposal ID");
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.isActive, "DAOVoting: Proposal is not active");
        require(msg.value == voteFee, "DAOVoting: Incorrect vote fee");

        // Check if user has voted
        Vote memory existingVote = votes[_proposalId][msg.sender];
        require(existingVote.timestamp > 0, "DAOVoting: No existing vote to change");
        require(existingVote.support != _newSupport, "DAOVoting: Vote unchanged");

        // Forward fee to treasury
        feeCollector.forwardFee{value: voteFee}();

        // Update vote counts
        if (existingVote.support) {
            proposal.yesVotes--;
        } else {
            proposal.noVotes--;
        }

        if (_newSupport) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }

        // Update vote record
        votes[_proposalId][msg.sender] = Vote({
            support: _newSupport,
            timestamp: block.timestamp
        });

        emit VoteChanged(_proposalId, msg.sender, existingVote.support, _newSupport, block.timestamp);

        // Auto-flag if threshold reached
        if (proposal.yesVotes >= flagThreshold && !proposal.isFlagged) {
            proposal.isFlagged = true;
            emit ProposalFlagged(_proposalId, proposal.yesVotes, proposal.noVotes, block.timestamp);
        }
    }

    /**
     * @dev Manually flag a proposal (admin only)
     * @param _proposalId ID of the proposal
     */
    function flagProposal(uint256 _proposalId) external onlyOwner {
        require(_proposalId > 0 && _proposalId <= proposalCount, "DAOVoting: Invalid proposal ID");
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.isActive, "DAOVoting: Proposal is not active");
        require(!proposal.isFlagged, "DAOVoting: Proposal already flagged");

        proposal.isFlagged = true;
        emit ProposalFlagged(_proposalId, proposal.yesVotes, proposal.noVotes, block.timestamp);
    }

    /**
     * @dev Get a single proposal
     * @param _proposalId ID of the proposal
     * @return Proposal struct
     */
    function getProposal(uint256 _proposalId) external view returns (Proposal memory) {
        require(_proposalId > 0 && _proposalId <= proposalCount, "DAOVoting: Invalid proposal ID");
        return proposals[_proposalId];
    }

    /**
     * @dev Get multiple proposals with pagination
     * @param _offset Starting index (0-based)
     * @param _limit Number of proposals to return
     * @return Array of Proposal structs
     */
    function getProposals(
        uint256 _offset,
        uint256 _limit
    ) external view returns (Proposal[] memory) {
        require(_limit > 0 && _limit <= 100, "DAOVoting: Invalid limit");
        require(_offset < proposalCount, "DAOVoting: Invalid offset");

        uint256 end = _offset + _limit;
        if (end > proposalCount) {
            end = proposalCount;
        }

        uint256 count = end - _offset;
        Proposal[] memory result = new Proposal[](count);

        for (uint256 i = 0; i < count; i++) {
            result[i] = proposals[_offset + i + 1]; // proposal IDs start at 1
        }

        return result;
    }

    /**
     * @dev Check if a user has voted on a proposal
     * @param _proposalId ID of the proposal
     * @param _user Address of the user
     * @return true if user has voted
     */
    function hasUserVoted(uint256 _proposalId, address _user) external view returns (bool) {
        require(_proposalId > 0 && _proposalId <= proposalCount, "DAOVoting: Invalid proposal ID");
        return votes[_proposalId][_user].timestamp > 0;
    }

    /**
     * @dev Get a user's vote for a proposal
     * @param _proposalId ID of the proposal
     * @param _user Address of the user
     * @return Vote struct (timestamp will be 0 if no vote)
     */
    function getUserVote(uint256 _proposalId, address _user) external view returns (Vote memory) {
        require(_proposalId > 0 && _proposalId <= proposalCount, "DAOVoting: Invalid proposal ID");
        return votes[_proposalId][_user];
    }

    /**
     * @dev Set submission fee (admin only)
     * @param _newFee New submission fee
     */
    function setSubmissionFee(uint256 _newFee) external onlyOwner {
        uint256 oldFee = submissionFee;
        submissionFee = _newFee;
        emit SubmissionFeeUpdated(oldFee, _newFee);
    }

    /**
     * @dev Set vote fee (admin only)
     * @param _newFee New vote fee
     */
    function setVoteFee(uint256 _newFee) external onlyOwner {
        uint256 oldFee = voteFee;
        voteFee = _newFee;
        emit VoteFeeUpdated(oldFee, _newFee);
    }

    /**
     * @dev Set flag threshold (admin only)
     * @param _newThreshold New flag threshold
     */
    function setFlagThreshold(uint256 _newThreshold) external onlyOwner {
        uint256 oldThreshold = flagThreshold;
        flagThreshold = _newThreshold;
        emit FlagThresholdUpdated(oldThreshold, _newThreshold);
    }

    /**
     * @dev Set fee collector (admin only)
     * @param _feeCollector New fee collector address
     */
    function setFeeCollector(address _feeCollector) external onlyOwner {
        require(_feeCollector != address(0), "DAOVoting: Invalid fee collector");
        address oldCollector = address(feeCollector);
        feeCollector = FeeCollector(_feeCollector);
        emit FeeCollectorUpdated(oldCollector, _feeCollector);
    }
}

