// SPDX-License-Identifier: GPL-3.0;
pragma solidity ^0.8.0;
import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol';
contract Dao {
    // Global Variables
    address nativeToken;
    uint public totalTokenByMembers;
    uint public votingDuration;
    uint requiredAmountOfToken;
    // should be fixed
    uint public maxFundingDuration;
    // Proposals
    struct ProjectProposal {
        address projectOwner;
        // address projectWallet;
        string projectName;
        string projectDescription;
        uint createdAt;
        uint yesVotes;
        uint noVotes;
        ProposalVotingState proposalVotingState;
        mapping(address => Vote) votesByMember;
        mapping(address => uint) contributor;
        address[] contributors;
    }
    enum ProposalVotingState{
            REJECTED,
            ONGOING,
            APPROVED
    }
    uint projectId;
    ProjectProposal[] ProjectProposals;
    mapping(uint => ProjectProposal) public project_Proposal;
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
    event Result(uint projectId, ProposalVotingState result, uint yesVotes, uint noVotes);
    event NewMember(address member_, string message);
    event SubmittedProjectProposal(string projectName);
    event Votes(uint projectId_, uint yesVotes, uint noVotes);
    
    constructor (address _admin, address _token) {
        require(_admin != address(0), 'Only Admin can call this function');
        votingDuration = 7 days;
        maxFundingDuration = 30 days;
        admin = _admin;
        nativeToken = _token;
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
    // PROPOSAL FUNCTIONS
    function SubmitProjectProposal(address _projectOwner, string memory _projectName,string memory _projectDescription) public {
        IERC20 token = IERC20(nativeToken);
        require (token.balanceOf(_projectOwner) >= 1000, "HGN: Insufficient token to submit proposal");
        require (_projectOwner != address(0), "Owner's address cannot be address zero");
        ProjectProposal storage project =  project_Proposal[projectId];
        project.projectOwner = _projectOwner;
        project.projectName = _projectName;
        project.projectDescription = _projectDescription;
        project.proposalVotingState = ProposalVotingState.ONGOING;
        project.createdAt = block.timestamp;
        projectId++;
        emit SubmittedProjectProposal(_projectName);
    }
    function vote(uint _projectId, uint8 _vote) public onlyDaoMember {
        require (_projectId < projectId);
        ProjectProposal storage project =  project_Proposal[_projectId];
        require (project.proposalVotingState == ProposalVotingState.ONGOING);
        require (block.timestamp <= (project.createdAt + votingDuration), 'Voting closed');
        require (project.votesByMember[msg.sender] == Vote.Null, 'Already voted');
        require (_vote < 3,'Invalid Selection');
        Vote vote_ = Vote(_vote);
        DaoMember memory _daoMember = DaoMembers[msg.sender];
        if (vote_ == Vote.Yes) {
            project.yesVotes += _daoMember.votingPower;
            project.votesByMember[msg.sender] = Vote.Yes;
        }
        if (vote_ == Vote.No) {
            project.noVotes += _daoMember.votingPower;
            project.votesByMember[msg.sender] = Vote.No;
        }
        emit Votes(_projectId, project.yesVotes, project.noVotes);
    }
    function updateVotingState(uint projectId_) public {
        require (projectId_ < projectId);
        ProjectProposal storage project =  project_Proposal[projectId_];
        require (block.timestamp >= (project.createdAt + votingDuration), 'Voting closed');
        if (project.yesVotes > project.noVotes) {
            project.proposalVotingState = ProposalVotingState.APPROVED;
        } else {
            project.proposalVotingState = ProposalVotingState.REJECTED;
        }
        emit Result(projectId_, project.proposalVotingState, project.yesVotes, project.noVotes);
    }
}
5:35
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
import "./TimeLockedWalletFactory.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract FundProject is TimeLockedWalletFactory{
    
    uint maxFundingPeriod;
    address admin;
    address wallet;
    uint projectId;
    
    struct Project {
        string projectName;
        string projectDescription;
        address projectOwner;
        address projectWallet;
        uint fundRequested;
        uint fundRaised;
        uint fundingStartDate;
        uint fundingEndDate;
        uint unitPrice;
        mapping (address => uint) contributorsToToken;
        address[] contributors;
    }
    mapping(uint => Project ) OwnerToProject;
    
    constructor (address _admin) {
        maxFundingPeriod = 30 days;
        admin = _admin;
    }
    
    modifier onlyAdmin(){
        require(msg.sender == admin, 'Only Admin can call this function');
        _;
    }
    
    event createdProject (string projectName, address wallet, uint fundRequested);
    
    function createProject(
        string memory _projectName,
        string memory _projectDescription, 
        address payable _projectOwner,
        uint _fundRequested, 
        uint _fundingStartDate, 
        uint _fundingEndDate, 
        uint _unitPrice) public onlyAdmin {
           require (_fundingEndDate - _fundingStartDate < maxFundingPeriod);
           wallet = TimeLockedWalletFactory.newTimeLockedWallet(admin, _projectOwner, _fundingEndDate);
           Project storage project =  OwnerToProject[projectId];
           project.projectWallet = wallet;
           project.projectName = _projectName;
           project.projectDescription = _projectDescription;
           project.projectOwner = _projectOwner;
           project.fundRequested = _fundRequested;
           project.fundingStartDate = _fundingStartDate;
           project.fundingEndDate = _fundingEndDate;
           project.unitPrice = _unitPrice;
           projectId++;
           emit createdProject (_projectName, wallet, _fundRequested);
        }
        
        
    function fundProject(uint _projectId, uint amount) public {
        Project storage project =  OwnerToProject[_projectId];
        require (block.timestamp > project.fundingStartDate, "Funding has not started");
        require (block.timestamp < project.fundingEndDate, "Funding has ended");
        ERC20 token = ERC20(0x5eD8BD53B0c3fa3dEaBd345430B1A3a6A4e8BD7C);
        token.transferFrom(msg.sender, project.projectWallet, amount);
        project.fundRaised += amount;
        uint numberOfToken = amount / project.unitPrice;
        project.contributorsToToken[msg.sender] =numberOfToken;
    }
        
    
        
        
        
        
        
        
        
        
}