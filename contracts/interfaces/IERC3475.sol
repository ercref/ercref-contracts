pragma solidity ^0.8.0;

interface IERC3475Bank {

/**
* Issue
* @notice Issue MUST trigger when Bonds are issued. This SHOULD not include zero value Issuing.
* @dev This SHOULD not include zero value issuing.
* @dev Issue MUST be triggered when the operator (i.e Bank address) contract issues bonds to the given entity.
*/
event Issue(address indexed _operator, address indexed _to, Transaction[] _transactions);

/**
* Redeem
* @notice Redeem MUST trigger when Bonds are redeemed. This SHOULD not include zero value redemption.
*/
event Redeem(address indexed _operator, address indexed _from, uint256 classId, uint256 nonceId, uint256 _amount);

// TODO this final ERC lacks BURN event definition

/**
* Transfer
* @dev its emitted when the bond is transferred by address(operator) from owner address(_from) to address(_to) with the bonds transferred, whose params are defined by _transactions struct array.
* @dev Transfer MUST trigger when Bonds are transferred. This SHOULD not include zero value transfers.
* @dev Transfer event with the _from `0x0` MUST not create this event(use `event Issued` instead).
*/
event Transfer(address indexed _operator, address indexed _from, address indexed _to, Transaction[] _transactions);

/**
* ApprovalFor
* @dev its emitted when address(_owner) approves the address(_operator) to transfer his bonds.
* @notice Approval MUST trigger when bond holders are approving an _operator. This SHOULD not include zero value approval.
*/
event ApprovalFor(address indexed _owner, address indexed _operator, bool _approved);
/**
* transferFrom
* @param _from argument is the address of the bond holder whose balance is about to decrease.
* @param _to argument is the address of the bond recipient whose balance is about to increase.
* @param _transactions is the `Transaction[] calldata` (of type ['classId', 'nonceId', '_amountBonds']) structure defined in the rationale section below.
* @dev transferFrom MUST have the `isApprovedFor(_from, _to, _transactions[i].classId)` approval to transfer `_from` address to `_to` address for given classId (i.e for Transaction tuple corresponding to all nonces).
*/
// function transferFrom(0x2d03B6C79B75eE7aB35298878D05fe36DC1fE8Ef, 0x82a55a613429Aeb3D01fbE6841bE1AcA4fFD5b2B, [IERC3475.Transaction(1,14,500)]);
// transfer from `_from` address, to `_to` address, `500000000` bonds of type class`1` and nonce `42`.
function transferFrom(address _from, address _to, Transaction[] calldata _transactions) external;

/**
* transferAllowanceFrom
* @dev allows the transfer of only those bond types and nonces being allotted to the _to address using allowance().
* @param _from is the address of the holder whose balance is about to decrease.
* @param _to is the address of the recipient whose balance is about to increase.
* @param _transactions is the `Transaction[] calldata` structure defined in the section `rationale` below.
* @dev transferAllowanceFrom MUST have the `allowance(_from, msg.sender, _transactions[i].classId, _transactions[i].nonceId)` (where `i` looping for [ 0 ...Transaction.length - 1] )
*/
// function transferAllowanceFrom(0x2d03B6C79B75eE7aB35298878D05fe36DC1fE8Ef, 0x82a55a613429Aeb3D01fbE6841bE1AcA4fFD5b2B, [IERC3475.Transaction(1,14,500)]);
// transfer from `_from` address, to `_to` address, `500000000` bonds of type class`1` and nonce `42`.
function transferAllowanceFrom(address _from,address _to, Transaction[] calldata _transactions) external;

/**
* issue
* @dev allows issuing any number of bond types (defined by values in Transaction tuple as param) to an address.
* @dev it MUST be issued by a single entity (for instance, a role-based ownable contract that has integration with the liquidity pool of the deposited collateral by `_to` address).
* @param _to argument is the address to which the bond will be issued.
* @param _transaction is the `Transaction[] calldata` (ie array of issued bond class, bond nonce and amount of bonds to be issued).
* @dev transferAllowanceFrom MUST have the `allowance(_from, msg.sender, _transactions[i].classId, _transactions[i].nonceId)` (where `i` looping for [ 0 ...Transaction.length - 1] )
*/
function issue(address _to, Transaction[] calldata _transaction) external;

/**
* redeem
* @dev permits redemption of bond from an address.
* @dev the calling of this function needs to be restricted to the bond issuer contract.
* @param `_from` is the address from which the bond will be redeemed.
* @param `_transactions` is the `Transaction[] calldata` structure (i.e., array of tuples with the pairs of (class, nonce and amount) of the bonds that are to be redeemed). Further defined in the rationale section.
* @dev redeem function for a given class, and nonce category MUST BE done after certain conditions for maturity (can be end time, total active liquidity, etc.) are met.
* @dev furthermore, it SHOULD ONLY be called by the bank or secondary market maker contract.
*/
// redeem(0x2d03B6C79B75eE7aB35298878D05fe36DC1fE8Ef, [IERC3475.Transaction(1,14,500)]);
// means “redeem from wallet address(0x2d03B6C79B75eE7aB35298878D05fe36DC1fE8Ef), 500000000 of bond class1 and nonce 42.
function redeem(address _from, Transaction[] calldata _transactions) external;

/**
* burn
* @dev permits nullifying of the bonds (or transferring given bonds to address(0)).
* @dev burn function for given class and nonce MUST BE called by only the controller contract.
* @param _from is the address of the holder whose bonds are about to burn.
* @param `_transactions` is the `Transaction[] calldata` structure (i.e., array of tuple with the pairs of (class, nonce and amount) of the bonds that are to be burned). further defined in the rationale.
* @dev burn function for a given class, and nonce category MUST BE done only after certain conditions for maturity (can be end time, total active liquidity, etc).
* @dev furthermore, it SHOULD ONLY be called by the bank or secondary market maker contract.
*/
// burnBond(0x82a55a613429Aeb3D01fbE6841bE1AcA4fFD5b2B,[IERC3475.Transaction(1,14,500)]);
// means burning 500000000 bonds of class 1 nonce 42 owned by address 0x82a55a613429Aeb3D01fbE6841bE1AcA4fFD5b2B.
function burn(address _from, Transaction[] calldata _transactions) external;

/**
* approve
* @dev Allows `_spender` to withdraw from the msg.sender the bonds of `_amount` and type (classId and nonceId).
* @dev If this function is called again, it overwrites the current allowance with the amount.
* @dev `approve()` should only be callable by the bank, or the owner of the account.
* @param `_spender` argument is the address of the user who is approved to transfer the bonds.
* @param `_transactions` is the `Transaction[] calldata` structure (ie array of tuple with the pairs of (class,nonce, and amount) of the bonds that are to be approved to be spend by _spender). Further defined in the rationale section.
*/
// approve(0x82a55a613429Aeb3D01fbE6841bE1AcA4fFD5b2B,[IERC3475.Transaction(1,14,500)]);
// means owner of address 0x82a55a613429Aeb3D01fbE6841bE1AcA4fFD5b2B is approved to manage 30000 bonds from class 0 and Nonce 1.
function approve(address _spender, Transaction[] calldata _transactions) external;

/**
* SetApprovalFor
* @dev enable or disable approval for a third party (“operator”) to manage all the Bonds in the given class of the caller’s bonds.
* @dev If this function is called again, it overwrites the current allowance with the amount.
* @dev `approve()` should only be callable by the bank or the owner of the account.
* @param `_operator` is the address to add to the set of authorized operators.
* @param `classId` is the class id of the bond.
* @param `_approved` is true if the operator is approved (based on the conditions provided), false meaning approval is revoked.
* @dev contract MUST define internal function regarding the conditions for setting approval and should be callable only by bank or owner.
*/
// setApprovalFor(0x82a55a613429Aeb3D01fbE6841bE1AcA4fFD5b2B,0,true);
// means that address 0x82a55a613429Aeb3D01fbE6841bE1AcA4fFD5b2B is authorized to transfer bonds from class 0 (across all nonces).
function setApprovalFor(address _operator, bool _approved) external returns(bool approved);

/**
* totalSupply
* @dev Here, total supply includes burned and redeemed supply.
* @param classId is the corresponding class Id of the bond.
* @param nonceId is the nonce Id of the given bond class.
* @return the supply of the bonds
*/
// totalSupply(0, 1);
// it finds the total supply of the bonds of classid 0 and bond nonce 1.
function totalSupply(uint256 classId, uint256 nonceId) external view returns (uint256);

/**
* redeemedSupply
* @dev Returns the redeemed supply of the bond identified by (classId,nonceId).
* @param classId is the corresponding class id of the bond.
* @param nonceId is the nonce id of the given bond class.
* @return the supply of bonds redeemed.
*/
function redeemedSupply(uint256 classId, uint256 nonceId) external view returns (uint256);

/**
* activeSupply
* @dev Returns the active supply of the bond defined by (classId,NonceId).
* @param classId is the corresponding classId of the bond.
* @param nonceId is the nonce id of the given bond class.
* @return the non-redeemed, active supply.
*/
function activeSupply(uint256 classId, uint256 nonceId) external view returns (uint256);

/**
* burnedSupply
* @dev Returns the burned supply of the bond in defined by (classId,NonceId).
* @param classId is the corresponding classId of the bond.
* @param nonceId is the nonce id of the given bond class.
* @return gets the supply of bonds for given classId and nonceId that are already burned.
*/
function burnedSupply(uint256 classId, uint256 nonceId) external view returns (uint256);

/**
* balanceOf
* @dev Returns the balance of the bonds (nonReferenced) of given classId and bond nonce held by the address `_account`.
* @param classId is the corresponding classId of the bond.
* @param nonceId is the nonce id of the given bond class.
* @param _account address of the owner whose balance is to be determined.
* @dev this also consists of bonds that are redeemed.
*/
function balanceOf(address _account, uint256 classId, uint256 nonceId) external view returns (uint256);

/**
* classMetadata
* @dev Returns the JSON metadata of the classes.
* @dev The metadata SHOULD follow a set of structures explained later in the metadata.md
* @param metadataId is the index-id given bond class information.
* @return the JSON metadata of the nonces. — e.g. `[title, type, description]`.
*/
function classMetadata(uint256 metadataId) external view returns (Metadata memory);

/**
* nonceMetadata
* @dev Returns the JSON metadata of the nonces.
* @dev The metadata SHOULD follow a set of structures explained later in metadata.md
* @param classId is the corresponding classId of the bond.
* @param nonceId is the nonce id of the given bond class.
* @param metadataId is the index of the JSON storage for given metadata information. more is defined in metadata.md.
* @returns the JSON metadata of the nonces. — e.g. `[title, type, description]`.
*/
function nonceMetadata(uint256 classId, uint256 metadataId) external view returns (Metadata memory);

/**
* classValues
* @dev allows anyone to read the values (stored in struct Values for different class) for given bond class `classId`.
* @dev the values SHOULD follow a set of structures as explained in metadata along with correct mapping corresponding to the given metadata structure
* @param classId is the corresponding classId of the bond.
* @param metadataId is the index of the JSON storage for given metadata information of all values of given metadata. more is defined in metadata.md.
* @returns the Values of the class metadata. — e.g. `[string, uint, address]`.
*/
function classValues(uint256 classId, uint256 metadataId) external view returns (Values memory);

/**
* nonceValues
* @dev allows anyone to read the values (stored in struct Values for different class) for given bond (`nonceId`,`classId`).
* @dev the values SHOULD follow a set of structures explained in metadata along with correct mapping corresponding to the given metadata structure
* @param classId is the corresponding classId of the bond.
* @param metadataId is the index of the JSON storage for given metadata information of all values of given metadata. More is defined in metadata.md.
* @returns the Values of the class metadata. — e.g. `[string, uint, address]`.
*/
function nonceValues(uint256 classId, uint256 nonceId, uint256 metadataId) external view returns (Values memory);

/**
* getProgress
* @dev Returns the parameters to determine the current status of bonds maturity.
* @dev the conditions of redemption SHOULD be defined with one or several internal functions.
* @param classId is the corresponding classId of the bond.
* @param nonceId is the nonceId of the given bond class .
* @returns progressAchieved defines the metric (either related to % liquidity, time, etc.) that defines the current status of the bond.
* @returns progressRemaining defines the metric that defines the remaining time/ remaining progress.
*/
function getProgress(uint256 classId, uint256 nonceId) external view returns (uint256 progressAchieved, uint256 progressRemaining);

/**
* allowance
* @dev Authorizes to set the allowance for given `_spender` by `_owner` for all bonds identified by (classId, nonceId).
* @param _owner address of the owner of bond(and also msg.sender).
* @param _spender is the address authorized to spend the bonds held by _owner of info (classId, nonceId).
* @param classId is the corresponding classId of the bond.
* @param nonceId is the nonceId of the given bond class.
* @notice Returns the _amount which spender is still allowed to withdraw from _owner.
*/
function allowance(address _owner, address _spender, uint256 classId, uint256 nonceId) external view returns(uint256);

/**
* isApprovedFor
* @dev returns true if address _operator is approved for managing the account’s bonds class.
* @notice Queries the approval status of an operator for a given owner.
* @dev _owner is the owner of bonds.
* @dev _operator is the EOA /contract, whose status for approval on bond class for this approval is checked.
* @returns “true” if the operator is approved, “false” if not.
*/
function isApprovedFor(address _owner, address _operator) external view returns (bool);
}
