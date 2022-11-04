// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "./TSSaleFactory.sol";

contract TSAutomation is Ownable,Pausable,AutomationCompatibleInterface{

    event KeeperRegistryAddressUpdated(address oldAddress, address newAddress);

    modifier onlyKeeperRegistry() {
        require(msg.sender==s_keeperRegistryAddress,"DS: only keeper call");
        _;
    }

    constructor(address _saleAddress) {
        addressSaleFactory = _saleAddress;
    }

    address private s_keeperRegistryAddress;
    address private addressSaleFactory;
    mapping(uint256 => bool) private saleIds;

        /**
    * @notice Pauses the contract, which prevents executing performUpkeep
    */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    function setSaleAddress(address _saleAddress) public onlyOwner {
        addressSaleFactory = _saleAddress;
    }

    function getSaleAddress() public view returns(address) {
        return addressSaleFactory;
    }

    function getIdSummary() private view returns (uint256 saleId) {
        TSSaleFactory saleFactory = TSSaleFactory(payable(addressSaleFactory));
        for(uint256 idx=0; idx<saleFactory.getLengthConfig(); idx++) {
            if(saleIds[idx])
                continue;
            TSSaleFactory.SaleConfig memory saleConfig = saleFactory.getSaleConfigByIndex(idx);
            if(saleConfig.status==TSSaleFactory.SaleStatus.PENDING && saleConfig.endTime<=block.timestamp){
                saleId = idx+1;
                break;
            }
        }
    }

    /**
    * @notice Sets the Chainlink Automation registry address
    */
    function setKeeperRegistryAddress(address keeperRegistryAddress) public onlyOwner {
        require(keeperRegistryAddress != address(0));
        emit KeeperRegistryAddressUpdated(s_keeperRegistryAddress, keeperRegistryAddress);
        s_keeperRegistryAddress = keeperRegistryAddress;
    }

    /**
    * @notice Gets the Chainlink Automation registry address
    */
    function getKeeperRegistryAddress() external view returns (address b) {
        return s_keeperRegistryAddress;
    }

    function checkUpkeep(bytes calldata) external view override whenNotPaused returns (bool upkeepNeeded, bytes memory performData) {
        uint256 saleId = getIdSummary();
        upkeepNeeded = saleId > 0;
        performData = saleId>0 ? abi.encode(saleId-1) : abi.encode(saleId);
        return (upkeepNeeded,performData);
    }

    function performUpkeep(bytes calldata performData) external override onlyKeeperRegistry whenNotPaused {
        uint256 saleId = abi.decode(performData,(uint256));
        if (!saleIds[saleId]) {
            saleIds[saleId] = true;
            TSSaleFactory saleFactory = TSSaleFactory(payable(addressSaleFactory));
            TSSaleFactory.SaleConfig memory saleConfig = saleFactory.getSaleConfigByIndex(saleId);
            if(saleConfig.status == TSSaleFactory.SaleStatus.PENDING && saleConfig.endTime <= block.timestamp) {
                saleFactory.saleSummary(saleId);
            }
        }
    }
}