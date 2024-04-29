// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IFooDriverFactory {

    function fCreateStore(string memory _storeId, address _registry, address _bank, address _token) external returns (address store);

    function fGetStoreById(string memory _storeId) external view returns (address storeAddress) ;

}
