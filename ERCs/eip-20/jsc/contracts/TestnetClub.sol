pragma solidity ^0.8.0;

import "./AJointStockCompany.sol";

// Price per share will be 0.1 testnetETH + (number of shares purchased) / 1000
contract TestnetClub is Initializable, AJointStockCompany {

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer external {
        __AJointStockCompany_init('TestnetClub Shares', 'TCS');
    }

    function purchaseShares(uint256 amount) external payable {
        require(msg.value >= amount / decimals() * _pricePerShare(), "TestnetClub: incorrect amount");
        _mint(msg.sender, amount);
        // return excess
        if (msg.value > amount / decimals() * _pricePerShare()) {
            payable(msg.sender).transfer(msg.value - (amount / decimals() * _pricePerShare()));
        }
    }

    function pricePerShare() external view returns (uint256) {
        return _pricePerShare();
    }

    function _pricePerShare() internal view returns (uint256) {
        return 0.1 ether + ((this.totalSupply() / decimals()) / 1000);
    }
}