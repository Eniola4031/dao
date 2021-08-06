// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
import “./TimeLockedWalletFactory.sol”;
import “./TimeLockedWallet.sol”;
import “@openzeppelin/contracts/token/ERC20/ERC20.sol”;
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
    mapping(uint => Project ) public OwnerToProject;
    constructor (address _admin) {
        maxFundingPeriod = 2592000;
        admin = _admin;
    }
    modifier onlyAdmin(){
        require(msg.sender == admin, ‘Only Admin can call this function’);
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
           require ((_fundingEndDate - _fundingStartDate) < maxFundingPeriod);
           wallet = TimeLockedWalletFactory.newTimeLockedWallet(admin, _projectOwner, _fundingEndDate);
           Project storage project =  OwnerToProject[projectId];
           project.projectWallet = wallet;
           project.projectName = _projectName;
           project.projectDescription = _projectDescription;
           project.projectOwner = _projectOwner;
           project.fundRequested = _fundRequested;
           project.fundingStartDate = _fundingStartDate;
           project.fundingEndDate = _fundingEndDate;
           project.unitPrice = _unitPrice * 10**18;
           projectId++;
           emit createdProject (_projectName, wallet, _fundRequested);
        }
    function fundProject(address _tokenContract,uint _projectId, uint amount) public payable {
        Project storage project =  OwnerToProject[_projectId];
        require (block.timestamp > project.fundingStartDate, “Funding has not started”);
        require (block.timestamp < project.fundingEndDate, “Funding has ended”);
        ERC20 token = ERC20(_tokenContract);
        token.transferFrom(msg.sender, project.projectWallet, amount);
        project.fundRaised += amount;
        uint numberOfToken = amount / project.unitPrice;
        project.contributorsToToken[msg.sender] =numberOfToken;
    }
    // function withdrawTokens(address _tokenContract, uint _projectId) public {
    //     Project storage project =  OwnerToProject[_projectId];
    //     require (msg.sender == project.projectOwner);
    //     require(_tokenContract != address(0), “Token not found”);
    //     require (block.timestamp < project.fundingEndDate, “Funding has ended”);
    //     ERC20 token = ERC20(_tokenContract);
    //     uint tokenBalance = token.balanceOf(project.projectWallet);
    //     token.transfer(msg.sender, tokenBalance);
    //     // emit WithdrewTokens(_tokenContract, msg.sender, tokenBalance);
    // }
}
