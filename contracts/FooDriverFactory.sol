// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {FooDriverStore} from "./FooDriverStore.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IFooDriverFactory} from "./interfaces/IFooDriverFactory.sol";
/**
 * @title FooDriverFactory
 * @dev Manages creation and tracking of FooDriverStore instances.
 */
contract FooDriverFactory is Initializable, UUPSUpgradeable, IFooDriverFactory {
    mapping(string => address) public storesById;
    address public registry;
    bytes32 public constant REGISTRY_ROLE = keccak256("REGISTRY_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");



    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    /**
     * @dev Initializes the factory with the registry address.
     */
    function initialize(address initialAuthority) initializer public {
        __UUPSUpgradeable_init();
        registry = initialAuthority;
    }

    error StoreAlreadyExists();
    error StoreDoesNotExist();
    error NotRegistry();
    error NotUpgrader();
    event StoreCreated(string storeId, address storeAddress);

    modifier onlyRegistry() {
        if (!IAccessControl(registry).hasRole(REGISTRY_ROLE, msg.sender)) {
            revert NotRegistry();
        }
        _;
    }
    modifier onlyUpgrader() {
        if (!IAccessControl(registry).hasRole(UPGRADER_ROLE, msg.sender)) {
            revert NotUpgrader();
        }
        _;
    }

    /**
     * @notice Creates a new FooDriverStore instance and maps it to an identifier.
     * @dev This function can only be called by an account with the `REGISTRY_ROLE`.
     * @param _storeId Unique identifier for the store.
     * @param _registry Address of the registry contract.
     * @param _bank Address of the associated bank contract.
     * @param _token Address of the token contract for transactions.
     * @return storeAddress Address of the newly created FooDriverStore contract.
     */
    function fCreateStore(string memory _storeId, address _registry, address _bank, address _token) public onlyRegistry returns (address storeAddress) {
        if (storesById[_storeId] != address(0)) {
            revert StoreAlreadyExists();
        }
        FooDriverStore store = new FooDriverStore(
            _storeId,
            _registry,
            _bank,
            _token);
        storesById[_storeId] = address(store);
        emit StoreCreated(_storeId, address(store));
        return address(store);
    }
    /**
       * @notice Retrieves the address of a store by its identifier.
     * @dev Returns the address of the specified store, errors if not found.
     * @param _storeId Unique identifier for the store.
     * @return storeAddress Address of the store associated with the given identifier.
     */
    function fGetStoreById(string memory _storeId) public view returns (address storeAddress) {
        if(storesById[_storeId] == address(0)) {
            revert StoreDoesNotExist();
        }
        return storesById[_storeId];
    }

    /**
        * @dev Authorizes an upgrade to a new implementation of this contract.
     * @param newImplementation Address of the new contract implementation.
     */
    function _authorizeUpgrade(address newImplementation)
    internal
    onlyUpgrader
    override
    {}
}
