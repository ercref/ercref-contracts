pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC1363Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC1363ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title JointStockCompany
 * @author Zainan Victor Zhou
 * @notice A JointStockCompany is a company with a defined "stock" that represents a share of the
 *         future revenue of a company.
 *         The company can issue new shares to investors, and investors can withdraw their earnings
 *         from the company.
 *         The company can support multiple tokens, and investors can withdraw their earnings in
 *         any of the supported tokens.
 *         Unlike a traditional stock when an income is received it's the company's discretion to
 *         decidew when and how much of the income to distribute to the shareholders, in this
 *         contract the income is distributed to under the name of the shareholders immediately.
 *         
 *         The company can also issue new shares to new shareholders to share the future income
 *         with them.
 * 
 *         TODO(xinbenlv): we haven't check for math overflow. DO NOT USE IN PRODUCTION.
 */
abstract contract AJointStockCompany is Initializable, 
    ERC20Upgradeable, IERC1363ReceiverUpgradeable {

    event SharesPurchased(address indexed buyer, uint256 amount);
    event SupportedTokenAdded(IERC1363Upgradeable indexed token);
    // Address = 0 are reserved for the native token of the blockchain
    // For mainnnet it's ETH
    // For goerli it's goerliETH
    // For sepolia its sepoliaETH

    /// @dev The tokens that the company supports.
    ///      specifically, when token address is 0x0, it means the native token of the blockchain
    ///      that the company is deployed on.
    ///      For example, Mainnet is ETH, Goerli is goerliETH, Sepolia is sepoliaETH
    IERC1363Upgradeable[] internal _supportTokens;
    mapping (address => mapping (IERC1363Upgradeable => uint256)) internal _virtualWithdrawnEarningsByOwner;
    mapping (IERC1363Upgradeable => uint256) _virtualTotalWithdrawnEarnings;
    mapping (IERC1363Upgradeable => uint256) _virtualTotalRetainedEarnings;

    function __AJointStockCompany_init(string memory name, string memory symbol) internal onlyInitializing {
        __ERC20_init(name, symbol);
    }

    /* --- Public or External Methods --- */

    /**
     * @notice Handle the receipt of ERC1363 tokens
     * @dev Any ERC1363 smart contract calls this function on the recipient
     * after a `transfer` or a `transferFrom`. This function MAY throw to revert and reject the
     * transfer. Return of other than the magic value MUST result in the
     * transaction being reverted.
     * Note: the token contract address is always the message sender.
     * 
     * @param amount uint256 The amount of tokens transferred
     * @return `bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"))` unless throwing
     */
    function onTransferReceived(
        address /*operator*/,
        address /*from*/,
        uint256 amount,
        bytes memory /*data*/
    ) external returns (bytes4) {
        _virtualTotalRetainedEarnings[IERC1363Upgradeable(msg.sender)]+= amount;
        return 0x4b1d4fbc; // bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"))
    }
    
    function getShares(address _to) external view returns (uint256) {
        return balanceOf(_to);
    }

    function getSupportTokens() external view returns (IERC1363Upgradeable[] memory) {
        return _supportTokens;
    }

    function getSupportTokenCount() external view returns (uint256) {
        return _supportTokens.length;
    }

    function withdrawableAmount(address _to, IERC1363Upgradeable _token) external view returns (uint256) {
        return _withdrawableAmount(_to, _token);
    }

    /* --- Internal or Private Methods --- */

    function _withdrawableAmount(address _to, IERC1363Upgradeable _token) internal view returns (uint256) {
        uint256 sharesOfTo = balanceOf(_to);
        _validateTotalRetainedToken(_token);
        return _virtualTotalRetainedEarnings[_token] / sharesOfTo - _virtualWithdrawnEarningsByOwner[_to][_token];
    }

    function _addSupportedToken(IERC1363Upgradeable _token) internal {
        _supportTokens.push(_token);
        emit SupportedTokenAdded(_token);
    }

    function _balanceOf(address _to) internal view returns (uint256) {
        // This was due to the fact we use ERC20Upgradeable from OZ
        // Ideally it should be _balances but we don't have access to it.
        return balanceOf(_to);
    }

    function _withdrawEarnings(address payable _to, IERC1363Upgradeable _token, uint256 _amount) internal {
        require(_amount > 0, "StockToken: amount must be greater than 0");
        _validateTotalRetainedToken(_token);

        uint256 localWithdrawableAmount = _withdrawableAmount(_to, _token);
        require(localWithdrawableAmount >= _amount, "StockToken: not enough retained amount");
        
        _virtualWithdrawnEarningsByOwner[_to][_token] += _amount;
        if (address(_token) == address(0)) _to.transfer(_amount);
        else _token.transfer(_to, _amount);
        _validateTotalRetainedToken(_token);    
    }

    // Disallow transfer
    function _transfer(address /*sender*/, address /*recipient*/, uint256 /*amount*/) internal virtual override {
        revert("StockToken: transfer is not supported for now.");
    }

    function _issueNewShare (address _to, uint256 _share) internal {
        // When issueing new share
        // It's equivalent that the new share part of retained earnings are withdrawn
        for (uint256 i = 0; i < _supportTokens.length; i++) {
            IERC1363Upgradeable _token = _supportTokens[i];
            _validateTotalRetainedToken(_token);
            uint256 _totalVirtualRetainedEarningOfToken = _virtualTotalRetainedEarnings[_token];
            uint256 _virtualWithdrawnEarningsByNewShare = _totalVirtualRetainedEarningOfToken / _share;
            _virtualWithdrawnEarningsByOwner[_to][_token] = _virtualWithdrawnEarningsByNewShare;
            _virtualTotalRetainedEarnings[_token] += _virtualWithdrawnEarningsByNewShare;
            _virtualTotalWithdrawnEarnings[_token] += _virtualWithdrawnEarningsByNewShare;
            _validateTotalRetainedToken(_token);
        }
        _mint(_to, _share);
    }

    function _validateTotalRetainedToken(IERC1363Upgradeable _token) view internal {
        uint256 expectedBalance = 
            _virtualTotalRetainedEarnings[_token] - 
            _virtualTotalWithdrawnEarnings[_token];
        require(
            (address(_token) != address(0) ? _token.balanceOf(address(this)) :  address(this).balance) >= expectedBalance, 
            "StockToken: Company has insufficient balance");
    }

    uint256[50] private __gap;
}