interface ICommunityManager {
  function initializeCommunity() external returns (bool);
  // Registrar functions
  function addMember(address _member, bytes32 _label) external returns (bytes32);
  function addMemberWithRole(address _member, bytes32 _label, bytes32 _role) external returns (bytes32);
  function removeMember(address _member) external returns (bool);
  // Maintenance functions
  function updateSubdomain(address _member, bytes32 _label) external returns (bytes32);
  function updateRole(address _member, bytes32 _role, bool _revoke)external returns (bool);
}
