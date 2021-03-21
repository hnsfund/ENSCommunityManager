//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

import "hardhat/console.sol";
import { AccessControl } from  "@openzeppelin/contracts/access/AccessControl.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ENS } from "./ENS.sol";
import { ICommunityManager } from "./ICommunityManager.sol";

contract CommunityManager is ERC721, AccessControl, ICommunityManager {
  ENS ens;
  bytes32 public rootNode;

  // ENS labelhash of 'admin' to create admin.{dao domain}.eth
  bytes32 private constant ADMIN_LABEL = 0xf23ec0bb4210edd5cba85afd05127efcd2fc6a781bfed49188da1081670b22d8;
  bytes32 public constant MEMBER_ROLE = keccak256("MEMBER");
  bytes32 public constant OPERATIONS_ROLE = keccak256("OPERATIONS");
  bytes32[3] public ALL_ROLES = [DEFAULT_ADMIN_ROLE, MEMBER_ROLE, OPERATIONS_ROLE];
 
  event MemberAdded(address indexed member, bytes32 domain, bytes32 role);
  event SubdomainUpdated(address indexed member, bytes32 domain);
  event MemberRemoved(address indexed member);

  struct Member {
    bytes32 label;
    bytes32 node;
  }

  // store the domain for dao member.
  mapping(address => Member) memberDomains;

  /**
   * @dev Creates new registrar for a domain that intends to be a directory of community members
   * @param _ens - ENS instance to act on
   * @param _rootNode - parent domain that subdomains will be issued on e.g. thedao.eth
   * @param _name - Name  of NFT
   * @param _symbol - Symbol for NFT
   */
  constructor(ENS _ens, bytes32 _rootNode, string memory _name, string memory _symbol)
    ERC721(_name, _symbol)
  {
    ens = _ens;
    rootNode= _rootNode;
    // give deployer  admin role + admin.{dao domain} subdomain
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    console.log("is admin after setup?", hasRole(DEFAULT_ADMIN_ROLE, _msgSender()));

  }

  
  function initializeCommunity() external override returns (bool) {
    require(isAdmin(_msgSender()), 'CommunityManager: no permission to launch this community');
    require(ens.owner(rootNode) == address(this), 'CommunityManager: manager must be owner of node to initialize');
    grantSubdomain(_msgSender(), ADMIN_LABEL);
    // Let Admin and Ops people manage member directory
    _setRoleAdmin(MEMBER_ROLE, OPERATIONS_ROLE);
    _setRoleAdmin(MEMBER_ROLE, DEFAULT_ADMIN_ROLE);
    return true;
  }


  /**
  8 @dev for v2 sinlgeton contract that  allows all communities to use a single contract instead of contract 1 per community
  //  */
  // function initializeCommunityV2(bytes32 node, bytes32 label, address admin) external returns (bytes32 communityDomain) {
  //   require(_msgSender() == ens.owner(node), 'CommunityManager: you do not control domain to create community');
  //   communityDomain = keccak256(abi.encodePacked(node, label));
  //   require(address(this) == ens.owner(communityDomain), 'CommunityManager: must give ownership of domain before initalizing community');
  // }

  modifier onlyOpsOrAdmins(address _member) {
    require(
      hasRole(DEFAULT_ADMIN_ROLE, _member) || hasRole(OPERATIONS_ROLE, _member),
      'CommunityManager: Only admin can access this function'
    );
    _;
  }

  function addMember(address _member, bytes32 _label)
    public override
    onlyOpsOrAdmins(msg.sender)
    returns (bytes32)
  {
    return addMemberWithRole(_member, _label, MEMBER_ROLE);
  }


  /**
    * @dev Creates a new member in community directory with desired subdomain.
    * If given an initial role other than MEMBER, they are also given MEMBER role by default
    * @param _member - New member of community to add
    * @param _label - ENS label hash for desired  subdomain on rootNode
    * @param _role - Initial role to give community member
   */
  function addMemberWithRole(address _member, bytes32 _label, bytes32 _role )
    public override
    onlyOpsOrAdmins(msg.sender)
    returns (bytes32 node)
  {
    require(!hasRole(MEMBER_ROLE, _member), 'CommunityRegistration: member already in community');
    node = grantSubdomain(_member, _label);
    grantRole(_role, _member);
    if(_role != MEMBER_ROLE) {
      // add member role for directory in addition to functional role
      grantRole(MEMBER_ROLE, _member);
    }
    emit MemberAdded(_member, node, _role);
    return node;
  }

  /**
    @dev removes a member from the directory, delets their subdomain, and revokes all roles.
    * If trying to remove an admin only an admin can call this function because Ops can't revoke Admin role
    * @param _member - Member to remove
   */
  function removeMember(address _member)
    external override
    onlyOpsOrAdmins(msg.sender)
    returns (bool)
  {
    revokeSubdomain(_member);

    for( uint256 i = 0; i < ALL_ROLES.length - 1; i++) {
      revokeRole(ALL_ROLES[i], _member);
    }
    emit MemberRemoved(_member);
    delete memberDomains[_member];
  }

  /**
    * @dev Lets Ops or Admins update roles on any member.
    * AccessControl.sol does not let a role grant/revoke the same role on someone else
    * Admin -> Ops -> Member is order of control
    * @param _member - member to update role on
    * @param _role - Role to grant/revoke on member
    * @param _revoke - whether to revoke or grant _role. True if revoke
   */
  function updateRole(address _member, bytes32 _role, bool _revoke)
    external override
    onlyOpsOrAdmins(msg.sender)
    returns (bool)
  {
    require(hasRole(MEMBER_ROLE, _member), 'CommunityManager: target is not a member');
    if(_revoke) {
      revokeRole(_role, _member);
    } else {
      grantRole(_role, _member);
    }
    return true;
  }

  function updateSubdomain(address _member, bytes32 _label) override external returns (bytes32) {
    require(isMember(_member), 'CommunityManager: target is not a member');
    require(msg.sender == _member || isOps(_member), 'CommunityManager: Only member or Ops team can update subdomain');
    revokeSubdomain(_member); // remove old subdomain
    return grantSubdomain(_member, _label);
  }

  /** Internal functions  */
  function grantSubdomain(address _member, bytes32 _label) internal returns (bytes32 node) {
    node = getValidSubdomain(_label);
    ens.setSubnodeOwner(rootNode, _label, _member);
    memberDomains[_member] = Member({
      label: _label,
      node: node
    });
    _mint(_member, uint(node)); // domain transferred in _beforeTokenTransfer
    return node;
  }

  /**
    * @dev Removes subdomain from user
    * @param _member - Community member to revoke subdomain from
   */
  function revokeSubdomain(address _member) internal returns  (bool) {
    Member memory m = memberDomains[_member];
    ens.setSubnodeOwner(rootNode, m.label, address(0));
    _burn(uint(m.node));
    delete memberDomains[_member];
    return true;
  }

  /**
    * @dev verifies subdomain is not reserved or already taken.
    * Returns full ENS node for subdomain from rootNode and _label
    * @param _label - ENS label
   */
  function getValidSubdomain(bytes32 _label) internal virtual returns (bytes32 node) {
    require(
      _label != ADMIN_LABEL || isAdmin(msg.sender),
      'CommunityRegistration: dont have permission to set "admin" subdomain'
    );
    node = keccak256(abi.encodePacked(node, _label));
    require(!ens.recordExists(node), 'CommunityRegistration: domain already allocated');
    return node;
  }

  /** Helpers for UI and contract integrations */

  function isMember(address _member) public view returns (bool) {
    return hasRole(MEMBER_ROLE, _member);
  }

  function isOps(address _member) public view returns (bool) {
    return hasRole(OPERATIONS_ROLE, _member);
  }

  function isAdmin(address _member) public view returns (bool) {
    return hasRole(DEFAULT_ADMIN_ROLE, _member);
  }

  function getMembersWithRole(bytes32 _role) public view returns (address[] memory members) {
    for(uint256 i = 0; i < getRoleMemberCount(_role) -1; i++) {
      members[i] = getRoleMember(_role, i);
    }
    return members;
  }

  /** @dev disable transfers. Only admin/ops can invite new members or change member addresses */
  function _transfer(address from, address to, uint256 tokenId) internal virtual override {}

}
