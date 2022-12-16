pragma solidity ^0.8.9;

/**
 * @title EIP-3525 Semi-Fungible Token Standard
 * Note: the EIP-165 identifier for this interface is 0xd5358140.
 */
interface IERC3525 /* is IERC165, IERC721 */ {
    /**
     * @dev MUST emit when value of a token is transferred to another token with the same slot,
     *  including zero value transfers (_value == 0) as well as transfers when tokens are created
     *  (`_fromTokenId` == 0) or destroyed (`_toTokenId` == 0).
     * @param _fromTokenId The token id to transfer value from
     * @param _toTokenId The token id to transfer value to
     * @param _value The transferred value
     */
    event TransferValue(uint256 indexed _fromTokenId, uint256 indexed _toTokenId, uint256 _value);

    /**
     * @dev MUST emit when the approval value of a token is set or changed.
     * @param _tokenId The token to approve
     * @param _operator The operator to approve for
     * @param _value The maximum value that `_operator` is allowed to manage
     */
    event ApprovalValue(uint256 indexed _tokenId, address indexed _operator, uint256 _value);

    /**
     * @dev MUST emit when the slot of a token is set or changed.
     * @param _tokenId The token of which slot is set or changed
     * @param _oldSlot The previous slot of the token
     * @param _newSlot The updated slot of the token
     */
    event SlotChanged(uint256 indexed _tokenId, uint256 indexed _oldSlot, uint256 indexed _newSlot);

    /**
     * @notice Get the number of decimals the token uses for value - e.g. 6, means the user
     *  representation of the value of a token can be calculated by dividing it by 1,000,000.
     *  Considering the compatibility with third-party wallets, this function is defined as
     *  `valueDecimals()` instead of `decimals()` to avoid conflict with EIP-20 tokens.
     * @return The number of decimals for value
     */
    function valueDecimals() external view returns (uint8);

    /**
     * @notice Get the value of a token.
     * @param _tokenId The token for which to query the balance
     * @return The value of `_tokenId`
     */
    function balanceOf(uint256 _tokenId) external view returns (uint256);

    /**
     * @notice Get the slot of a token.
     * @param _tokenId The identifier for a token
     * @return The slot of the token
     */
    function slotOf(uint256 _tokenId) external view returns (uint256);

    /**
     * @notice Allow an operator to manage the value of a token, up to the `_value`.
     * @dev MUST revert unless caller is the current owner, an authorized operator, or the approved
     *  address for `_tokenId`.
     *  MUST emit the ApprovalValue event.
     * @param _tokenId The token to approve
     * @param _operator The operator to be approved
     * @param _value The maximum value of `_toTokenId` that `_operator` is allowed to manage
     */
    function approve(
        uint256 _tokenId,
        address _operator,
        uint256 _value
    ) external payable;

    /**
     * @notice Get the maximum value of a token that an operator is allowed to manage.
     * @param _tokenId The token for which to query the allowance
     * @param _operator The address of an operator
     * @return The current approval value of `_tokenId` that `_operator` is allowed to manage
     */
    function allowance(uint256 _tokenId, address _operator) external view returns (uint256);

    /**
     * @notice Transfer value from a specified token to another specified token with the same slot.
     * @dev Caller MUST be the current owner, an authorized operator or an operator who has been
     *  approved the whole `_fromTokenId` or part of it.
     *  MUST revert if `_fromTokenId` or `_toTokenId` is zero token id or does not exist.
     *  MUST revert if slots of `_fromTokenId` and `_toTokenId` do not match.
     *  MUST revert if `_value` exceeds the balance of `_fromTokenId` or its allowance to the
     *  operator.
     *  MUST emit `TransferValue` event.
     * @param _fromTokenId The token to transfer value from
     * @param _toTokenId The token to transfer value to
     * @param _value The transferred value
     */
    function transferFrom(
        uint256 _fromTokenId,
        uint256 _toTokenId,
        uint256 _value
    ) external payable;


    /**
     * @notice Transfer value from a specified token to an address. The caller should confirm that
     *  `_to` is capable of receiving EIP-3525 tokens.
     * @dev This function MUST create a new EIP-3525 token with the same slot for `_to`,
     *  or find an existing token with the same slot owned by `_to`, to receive the transferred value.
     *  MUST revert if `_fromTokenId` is zero token id or does not exist.
     *  MUST revert if `_to` is zero address.
     *  MUST revert if `_value` exceeds the balance of `_fromTokenId` or its allowance to the
     *  operator.
     *  MUST emit `Transfer` and `TransferValue` events.
     * @param _fromTokenId The token to transfer value from
     * @param _to The address to transfer value to
     * @param _value The transferred value
     * @return ID of the token which receives the transferred value
     */
    function transferFrom(
        uint256 _fromTokenId,
        address _to,
        uint256 _value
    ) external payable returns (uint256);
}

/**
 * @title EIP-3525 Semi-Fungible Token Standard, optional extension for slot enumeration
 * @dev Interfaces for any contract that wants to support enumeration of slots as well as tokens
 *  with the same slot.
 * Note: the EIP-165 identifier for this interface is 0x3b741b9e.
 */
interface IERC3525SlotEnumerable is IERC3525 /* , IERC721Enumerable */ {

    /**
     * @notice Get the total amount of slots stored by the contract.
     * @return The total amount of slots
     */
    function slotCount() external view returns (uint256);

    /**
     * @notice Get the slot at the specified index of all slots stored by the contract.
     * @param _index The index in the slot list
     * @return The slot at `index` of all slots.
     */
    function slotByIndex(uint256 _index) external view returns (uint256);

    /**
     * @notice Get the total amount of tokens with the same slot.
     * @param _slot The slot to query token supply for
     * @return The total amount of tokens with the specified `_slot`
     */
    function tokenSupplyInSlot(uint256 _slot) external view returns (uint256);

    /**
     * @notice Get the token at the specified index of all tokens with the same slot.
     * @param _slot The slot to query tokens with
     * @param _index The index in the token list of the slot
     * @return The token ID at `_index` of all tokens with `_slot`
     */
    function tokenInSlotByIndex(uint256 _slot, uint256 _index) external view returns (uint256);
}


/**
 * @title EIP-3525 Semi-Fungible Token Standard, optional extension for approval of slot level
 * @dev Interfaces for any contract that wants to support approval of slot level, which allows an
 *  operator to manage one's tokens with the same slot.
 *  See https://eips.ethereum.org/EIPS/eip-3525
 * Note: the EIP-165 identifier for this interface is 0xb688be58.
 */
interface IERC3525SlotApprovable is IERC3525 {
    /**
     * @dev MUST emit when an operator is approved or disapproved to manage all of `_owner`'s
     *  tokens with the same slot.
     * @param _owner The address whose tokens are approved
     * @param _slot The slot to approve, all of `_owner`'s tokens with this slot are approved
     * @param _operator The operator being approved or disapproved
     * @param _approved Identify if `_operator` is approved or disapproved
     */
    event ApprovalForSlot(address indexed _owner, uint256 indexed _slot, address indexed _operator, bool _approved);

    /**
     * @notice Approve or disapprove an operator to manage all of `_owner`'s tokens with the
     *  specified slot.
     * @dev Caller SHOULD be `_owner` or an operator who has been authorized through
     *  `setApprovalForAll`.
     *  MUST emit ApprovalSlot event.
     * @param _owner The address that owns the EIP-3525 tokens
     * @param _slot The slot of tokens being queried approval of
     * @param _operator The address for whom to query approval
     * @param _approved Identify if `_operator` would be approved or disapproved
     */
    function setApprovalForSlot(
        address _owner,
        uint256 _slot,
        address _operator,
        bool _approved
    ) external payable;

    /**
     * @notice Query if `_operator` is authorized to manage all of `_owner`'s tokens with the
     *  specified slot.
     * @param _owner The address that owns the EIP-3525 tokens
     * @param _slot The slot of tokens being queried approval of
     * @param _operator The address for whom to query approval
     * @return True if `_operator` is authorized to manage all of `_owner`'s tokens with `_slot`,
     *  false otherwise.
     */
    function isApprovedForSlot(
        address _owner,
        uint256 _slot,
        address _operator
    ) external view returns (bool);
}


/**
 * @title EIP-3525 token receiver interface
 * @dev Interface for a smart contract that wants to be informed by EIP-3525 contracts when receiving values from ANY addresses or EIP-3525 tokens.
 * Note: the EIP-165 identifier for this interface is 0x009ce20b.
 */
interface IERC3525Receiver {
    /**
     * @notice Handle the receipt of an EIP-3525 token value.
     * @dev An EIP-3525 smart contract MUST check whether this function is implemented by the recipient contract, if the
     *  recipient contract implements this function, the EIP-3525 contract MUST call this function after a
     *  value transfer (i.e. `transferFrom(uint256,uint256,uint256,bytes)`).
     *  MUST return 0x009ce20b (i.e. `bytes4(keccak256('onERC3525Received(address,uint256,uint256,
     *  uint256,bytes)'))`) if the transfer is accepted.
     *  MUST revert or return any value other than 0x009ce20b if the transfer is rejected.
     * @param _operator The address which triggered the transfer
     * @param _fromTokenId The token id to transfer value from
     * @param _toTokenId The token id to transfer value to
     * @param _value The transferred value
     * @param _data Additional data with no specified format
     * @return `bytes4(keccak256('onERC3525Received(address,uint256,uint256,uint256,bytes)'))`
     *  unless the transfer is rejected.
     */
    function onERC3525Received(address _operator, uint256 _fromTokenId, uint256 _toTokenId, uint256 _value, bytes calldata _data) external returns (bytes4);

}

/**
 * @title EIP-3525 Semi-Fungible Token Standard, optional extension for metadata
 * @dev Interfaces for any contract that wants to support query of the Uniform Resource Identifier
 *  (URI) for the EIP-3525 contract as well as a specified slot.
 *  Because of the higher reliability of data stored in smart contracts compared to data stored in
 *  centralized systems, it is recommended that metadata, including `contractURI`, `slotURI` and
 *  `tokenURI`, be directly returned in JSON format, instead of being returned with a url pointing
 *  to any resource stored in a centralized system.
 *  See https://eips.ethereum.org/EIPS/eip-3525
 * Note: the EIP-165 identifier for this interface is 0xe1600902.
 */
interface IERC3525Metadata is
    IERC3525 /* , IERC721Metadata */
{
    /**
     * @notice Returns the Uniform Resource Identifier (URI) for the current EIP-3525 contract.
     * @dev This function SHOULD return the URI for this contract in JSON format, starting with
     *  header `data:application/json;`.
     *  See https://eips.ethereum.org/EIPS/eip-3525 for the JSON schema for contract URI.
     * @return The JSON formatted URI of the current EIP-3525 contract
     */
    function contractURI() external view returns (string memory);

    /**
     * @notice Returns the Uniform Resource Identifier (URI) for the specified slot.
     * @dev This function SHOULD return the URI for `_slot` in JSON format, starting with header
     *  `data:application/json;`.
     *  See https://eips.ethereum.org/EIPS/eip-3525 for the JSON schema for slot URI.
     * @return The JSON formatted URI of `_slot`
     */
    function slotURI(uint256 _slot) external view returns (string memory);
}
