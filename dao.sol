pragma solidity ^0.8.0;
import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol';
contract Dao {
    // Global Variables
    uint public totalTokenByMembers;
    uint public votingDuration;
    uint public maxVoteScore;
    uint public minVoteScore;
    uint requiredAmountOfToken;
    // should be fixed
    uint public maxFundingDuration;
    // Proposals
    struct ProjectProposal {
        address projectOwner;
        address projectWallet;
        string projectName;
        string projectDescription;
        uint fundRequested;
        uint fundRaised;
        uint fundingStartDate;
        uint fundingEndDate;
        uint createdAt;
        uint yesVotes;
        uint noVotes;
        ProposalVotingState proposalVotingState;
        ProposalFundingState proposalFundingState;
        mapping(address => Vote) votesByMember;
        mapping(address => uint) contributor;
        address[] contributors;
    }
    enum ProposalVotingState{
            REJECTED,
            PENDING,
            APPROVED
    }
    enum ProposalFundingState{
            ONGOING,
            FUNDED,
            CLOSED
    }
    uint projectId;
    ProjectProposal[] ProjectProposals;
    mapping(uint => ProjectProposal) public allProjectProposals;
    // DAO Members will be added by admin
    struct DaoMember{
        address member;
        uint votingPower;
        bool exists;
    }
    mapping(address => DaoMember) public DaoMembers;
    DaoMember[] allDaoMembers;
    // Votes
    // require that only approved proposal
    enum Vote { Null, No, Yes }
    // enum Payment { Start, Ongoing, Closed } // platform
    // constructor
    address admin;
    event Result(uint projectId, ProposalVotingState result);
    event NewMember(address member_, string message);
    event SubmittedProjectProposal(string projectName);
    event Votes(uint projectId_, uint yesVotes, uint noVotes);
    constructor (address _admin) {
        require(_admin != address(0), 'Only Admin can call this function');
        votingDuration = 7 days;
        maxFundingDuration = 30 days;
        admin = _admin;
    }
    modifier onlyAdmin(){
        require(msg.sender == admin, 'Only Admin can call this function');
        _;
    }
    modifier onlyDaoMember(){
        require(DaoMembers[msg.sender].votingPower > 0, "not a member");
        _;
    }
    function addDaoMember(address _member, uint _votingPower) public onlyAdmin returns(bool){
        DaoMember storage _daoMember = DaoMembers[_member];
        _daoMember.member =_member;
         _daoMember.votingPower = _votingPower;
         _daoMember.exists =  true;
        allDaoMembers.push(_daoMember);
        emit NewMember(_member, 'was Added');
        return true;
    }
    // function removeDaoMember(address _member) public onlyAdmin{
    //     delete DaoMembers[_member];
    // }
    // require (approvedProposal = ) require that only approved proposal can be listed for contribution
    // have an array of summon-approved proposal, require that only these proposal are listed for vote
    // require that the provided address is not address(0) in withdraw function!!
    // PROPOSAL FUNCTIONS
    function SubmitProjectProposal(
        address _projectOwner,
        string memory _projectName,
        string memory _projectDescription,
        uint _fundRequested,
        uint _fundStartDate,
        uint _fundEndDate) public {
        ProjectProposal storage project =  allProjectProposals[projectId];
        project.projectOwner = _projectOwner;
        project.projectName = _projectName;
        project.projectDescription = _projectDescription;
        project.fundRequested = _fundRequested;
        project.fundingStartDate = _fundStartDate;
        project.fundingEndDate = _fundEndDate;
        project.proposalVotingState = ProposalVotingState.PENDING;
        project.createdAt = block.timestamp;
        projectId++;
        emit SubmittedProjectProposal(_projectName);
    }
    function vote(uint _projectId, uint8 _vote) public onlyDaoMember {
        require (_projectId < projectId);
        ProjectProposal storage project =  allProjectProposals[_projectId];
        require (project.proposalVotingState == ProposalVotingState.PENDING);
        require (block.timestamp <= (project.createdAt + votingDuration), 'Voting closed');
        require (project.votesByMember[msg.sender] == Vote.Null, 'Already voted');
        require (_vote < 3,'Invalid Selection');
        Vote vote_ = Vote(_vote);
        DaoMember memory _daoMember = DaoMembers[msg.sender];
        if (vote_ == Vote.Yes) {
            project.yesVotes += _daoMember.votingPower;
        }
        if (vote_ == Vote.No) {
            project.noVotes += _daoMember.votingPower;
        }
        emit Votes(_projectId, project.yesVotes, project.noVotes);
    }
    function checkVoteResult(uint projectId_) public {
        require (projectId_ < projectId);
        ProjectProposal storage project =  allProjectProposals[projectId_];
        require (block.timestamp <= (project.createdAt + votingDuration), 'Voting closed');
        if (project.yesVotes > project.noVotes) {
            project.proposalVotingState == ProposalVotingState.APPROVED;
        } else {
            project.proposalVotingState == ProposalVotingState.REJECTED;
        }
        emit Result(projectId_, project.proposalVotingState);
    }
}