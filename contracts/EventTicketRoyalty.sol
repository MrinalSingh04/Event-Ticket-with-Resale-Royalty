// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract EventTicketRoyalty {
    string public name;
    string public symbol;
    address public immutable organizer;
    uint96 public immutable royaltyBps; // e.g., 500 = 5%
    uint256 public totalSupply;

    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => string) private _tokenURIs;

    struct Listing {
        address seller;
        uint256 price;
        bool active;
    }

    mapping(uint256 => Listing) public listings;
    mapping(uint256 => uint256) public primaryPrice;
    mapping(uint256 => bool) public minted;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event TicketMinted(
        uint256 indexed tokenId,
        address indexed to,
        uint256 primaryPrice,
        string uri
    );
    event PrimaryPurchased(
        uint256 indexed tokenId,
        address indexed buyer,
        uint256 price
    );
    event Listed(
        uint256 indexed tokenId,
        address indexed seller,
        uint256 price
    );
    event ListingCancelled(uint256 indexed tokenId, address indexed seller);
    event Resold(
        uint256 indexed tokenId,
        address indexed seller,
        address indexed buyer,
        uint256 price,
        uint256 royalty
    );

    error NotOwner();
    error InvalidPrice();
    error NotListed();
    error AlreadyListed();
    error NotSeller();

    constructor(
        string memory _name,
        string memory _symbol,
        address _organizer,
        uint96 _royaltyBps
    ) {
        require(_organizer != address(0), "Organizer required");
        require(_royaltyBps <= 2000, "Royalty too high (>20%)");
        name = _name;
        symbol = _symbol;
        organizer = _organizer;
        royaltyBps = _royaltyBps;
    }

    modifier onlyTokenOwner(uint256 tokenId) {
        if (_owners[tokenId] != msg.sender) revert NotOwner();
        _;
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        return _owners[tokenId];
    }

    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        return _tokenURIs[tokenId];
    }

    // -------------------- Minting --------------------
    function mintTicket(
        uint256 tokenId,
        string memory uri,
        uint256 _primaryPriceWei,
        address receiver
    ) public {
        require(!minted[tokenId], "Already minted");
        minted[tokenId] = true;

        address to = receiver == address(0) ? organizer : receiver;
        _owners[tokenId] = to;
        _balances[to] += 1;
        _tokenURIs[tokenId] = uri;
        totalSupply++;

        if (_primaryPriceWei > 0) {
            primaryPrice[tokenId] = _primaryPriceWei;
        }

        emit TicketMinted(tokenId, to, _primaryPriceWei, uri);
        emit Transfer(address(0), to, tokenId);
    }

    // -------------------- Primary Sale --------------------
    function buyPrimary(uint256 tokenId) public payable {
        uint256 price = primaryPrice[tokenId];
        require(price > 0, "Primary closed");
        require(_owners[tokenId] == organizer, "Not held by organizer");
        require(msg.value == price, "Incorrect payment");

        primaryPrice[tokenId] = 0;
        _transfer(organizer, msg.sender, tokenId);

        (bool ok, ) = organizer.call{value: msg.value}("");
        require(ok, "Payment failed");

        emit PrimaryPurchased(tokenId, msg.sender, price);
    }

    // -------------------- Resale --------------------
    function listForResale(uint256 tokenId, uint256 priceWei)
        public
        onlyTokenOwner(tokenId)
    {
        if (priceWei == 0) revert InvalidPrice();
        if (listings[tokenId].active) revert AlreadyListed();

        _transfer(msg.sender, address(this), tokenId);
        listings[tokenId] = Listing(msg.sender, priceWei, true);
        emit Listed(tokenId, msg.sender, priceWei);
    }

    function cancelListing(uint256 tokenId) public {
        Listing memory lst = listings[tokenId];
        if (!lst.active) revert NotListed();
        if (lst.seller != msg.sender) revert NotSeller();

        delete listings[tokenId];
        _transfer(address(this), msg.sender, tokenId);
        emit ListingCancelled(tokenId, msg.sender);
    }

    function buyResale(uint256 tokenId) public payable {
        Listing memory lst = listings[tokenId];
        if (!lst.active) revert NotListed();
        if (msg.value != lst.price) revert InvalidPrice();

        uint256 royalty = (msg.value * royaltyBps) / 10_000;
        uint256 sellerAmount = msg.value - royalty;

        (bool ok1, ) = organizer.call{value: royalty}("");
        require(ok1, "Royalty failed");
        (bool ok2, ) = lst.seller.call{value: sellerAmount}("");
        require(ok2, "Seller payment failed");

        delete listings[tokenId];
        _transfer(address(this), msg.sender, tokenId);

        emit Resold(tokenId, lst.seller, msg.sender, msg.value, royalty);
    }

    // -------------------- Internal Transfer --------------------
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        require(_owners[tokenId] == from, "Not owner");
        _owners[tokenId] = to;
        _balances[from] -= 1;
        _balances[to] += 1;
        emit Transfer(from, to, tokenId);
    }
}
