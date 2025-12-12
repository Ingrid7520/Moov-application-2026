// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract AgriSmartTraceability {
    event ProductRegistered(
        uint256 indexed productId,
        address indexed farmer,
        string ipfsCID,
        uint256 timestamp
    );
    
    struct Product {
        address farmer;
        string ipfsCID;
        uint256 timestamp;
        bool exists;
    }
    
    mapping(uint256 => Product) public products;
    
    function registerProduct(uint256 _productId, string memory _ipfsCID) public {
        require(!products[_productId].exists, "Product already registered");
        
        products[_productId] = Product({
            farmer: msg.sender,
            ipfsCID: _ipfsCID,
            timestamp: block.timestamp,
            exists: true
        });
        
        emit ProductRegistered(_productId, msg.sender, _ipfsCID, block.timestamp);
    }
    
    function getProductInfo(uint256 _productId) public view returns (
        address farmer,
        string memory ipfsCID,
        uint256 timestamp
    ) {
        require(products[_productId].exists, "Product does not exist");
        Product storage p = products[_productId];
        return (p.farmer, p.ipfsCID, p.timestamp);
    }
    
    function productExists(uint256 _productId) public view returns (bool) {
        return products[_productId].exists;
    }
}