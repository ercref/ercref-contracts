pragma solidity ^0.8.0;

import "./AJointStockCompany.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC1363Upgradeable.sol";
import "hardhat/console.sol";
// Price per share will be 0.1 testnetETH + (number of shares purchased) / 1000
contract TestnetClub is Initializable, AJointStockCompany {

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer external {
        __AJointStockCompany_init('TestnetClub Shares', 'TCS');
        _addSupportedToken(IERC1363Upgradeable(address(0)));
        _mint(msg.sender, 100 * 10**decimals()); // issue 1000 shares to the owner init
    }

    function purchaseShares(uint256 amountInShareFraction) external payable {
        console.log("TestnetClub: num of share %d", amountInShareFraction / 10**decimals());
        console.log("TestnetClub: remainder %d", amountInShareFraction % 10**decimals());
        
        uint256 charge = amountInShareFraction * _pricePerShareFraction();
        require(msg.value >= charge, "TestnetClub: insufficient funds");
        _mint(msg.sender, amountInShareFraction);
        // return excess
        if (msg.value > charge) {
            payable(msg.sender).transfer(msg.value - charge);
        }
    }

    function pricePerShareFraction() external view returns (uint256) {
        return _pricePerShareFraction();
    }

    // XXX need to change to TrillionFractionalShare
    function _pricePerShareFraction() internal view returns (uint256) {
        return (10**17) / (10**this.decimals());
    }
}