// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EducationalResourceContract {
    address public owner;
    uint256 public accessFee;
    string private resourceHash; // IPFS or other hash representing the resource
    uint256 public royaltyPercentage; // Royalty percentage for the original owner on resale
    mapping(address => bool) public hasAccess;
    mapping(address => uint256) public resalePrice;

    event AccessGranted(address indexed user);
    event ResourceAccessed(address indexed user);
    event ResaleListed(address indexed user, uint256 price);
    event ResaleCompleted(address indexed seller, address indexed buyer, uint256 price, uint256 royalty);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier onlyIfHasAccess() {
        require(hasAccess[msg.sender], "You do not have access to this resource");
        _;
    }

    constructor(uint256 _accessFee, string memory _resourceHash, uint256 _royaltyPercentage) {
        owner = msg.sender;
        accessFee = _accessFee;
        resourceHash = _resourceHash;
        royaltyPercentage = _royaltyPercentage;
    }

    function grantAccess() public payable {
        require(msg.value >= accessFee, "Insufficient payment for access");
        require(!hasAccess[msg.sender], "Access already granted");

        hasAccess[msg.sender] = true;
        payable(owner).transfer(msg.value);

        emit AccessGranted(msg.sender);
    }

    function accessResource() public onlyIfHasAccess returns (string memory) {
        emit ResourceAccessed(msg.sender);
        return resourceHash;
    }

    function listForResale(uint256 price) public onlyIfHasAccess {
        resalePrice[msg.sender] = price;
        emit ResaleListed(msg.sender, price);
    }

    function purchaseResale(address seller) public payable {
        uint256 price = resalePrice[seller];
        require(price > 0, "Seller has not listed for resale");
        require(msg.value >= price, "Insufficient payment for resale");
        require(!hasAccess[msg.sender], "Buyer already has access");

        uint256 royalty = (price * royaltyPercentage) / 100;
        uint256 sellerProceeds = price - royalty;

        hasAccess[msg.sender] = true;
        hasAccess[seller] = false;
        resalePrice[seller] = 0;

        payable(owner).transfer(royalty);
        payable(seller).transfer(sellerProceeds);

        emit ResaleCompleted(seller, msg.sender, price, royalty);
    }

    function updateAccessFee(uint256 newFee) public onlyOwner {
        accessFee = newFee;
    }

    function updateResourceHash(string memory newResourceHash) public onlyOwner {
        resourceHash = newResourceHash;
    }

    function updateRoyaltyPercentage(uint256 newPercentage) public onlyOwner {
        royaltyPercentage = newPercentage;
    }
}
