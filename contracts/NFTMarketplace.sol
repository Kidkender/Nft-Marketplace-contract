// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTMarketplace is ERC721URIStorage, ReentrancyGuard {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;
    Counters.Counter private _itemSold;
 
    address payable public owner;
    uint256 public listingPrice = 0.0025 ether;
    address private _contractAddress = address(this);

    mapping(uint256 tokenId => MarketItem) private _idMarketItem;
    
    struct MarketItem {
        uint256 tokenId;
        uint256 price;
        address payable seller;
        address payable owner;
        bool sold;
    }

    event IdMarketItemCreated(
        uint256 indexed tokenId,
        uint256 price,
        address seller,
        address owner,
        bool sold
    );

    event MarketItemSold(
        uint256 indexed tokenId,
        uint256 price,
        address seller,
        address owner
    );

    event TokenRelisted(
        uint256 indexed tokenId,
        address seller,
        uint256 price
    );

    constructor() ERC721("NFT Metaverse Token", "UNFT") {
        owner = payable(msg.sender);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only owner of marketplace can change the listing price");
        _;
    }

    function updateListingPrice(uint256 _listingPrice) public payable onlyOwner {
        if (listingPrice != _listingPrice) {
            listingPrice = _listingPrice;
        }
    }

    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    function createToken(string memory _tokenURI, uint256 _price) public nonReentrant payable returns (uint256 newTokenId) {
        _tokenIds.increment();
        newTokenId = _tokenIds.current();

        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, _tokenURI);

        _createMarketItem(newTokenId, _price);

    }

    function _createMarketItem(uint256 tokenId, uint256 price) private {
        require(price != 0, "Price must be greater than 0");
        require(msg.value == listingPrice, "price must be equal list price");

        _idMarketItem[tokenId] = MarketItem(tokenId,price, payable(msg.sender) , payable(_contractAddress), false);
        _transfer(msg.sender, _contractAddress, tokenId);
        emit IdMarketItemCreated(tokenId, price,msg.sender, _contractAddress,  false);
    }


    function reSellToken(uint256 _tokenId, uint256 _price) public nonReentrant payable {
        require(_idMarketItem[_tokenId].owner == msg.sender, "Only owner can reSell");

        require(msg.value == listingPrice, "Price must be equal list Price");
        _idMarketItem[_tokenId].sold = false;
        _idMarketItem[_tokenId].price = _price;
        _idMarketItem[_tokenId].seller = payable(msg.sender);
        _idMarketItem[_tokenId].owner = payable(_contractAddress);


        _itemSold.decrement();

        _transfer(msg.sender, _contractAddress, _tokenId);

        emit TokenRelisted(_tokenId, msg.sender, _price);

    }

    function createMarketSale(uint256 _tokenId) public nonReentrant payable   {
        uint256 price = _idMarketItem[_tokenId].price;

        require(msg.value == price, "Submit exact asking price");

        MarketItem storage item = _idMarketItem[_tokenId];
        item.owner = payable(msg.sender);
        item.sold = true;

        _itemSold.increment();

        _transfer(_contractAddress, msg.sender, _tokenId);
        payable(owner).transfer(listingPrice);
        item.seller.transfer(msg.value);
        
        emit MarketItemSold(_tokenId, price,item.seller, msg.sender);
    }

    function fetchMarketItem() public view returns (MarketItem[] memory items) {
        uint256 totalItemCount  = _tokenIds.current();

        uint256 unSoldItemCount = totalItemCount  - _itemSold.current();
        uint256 currentIndex = 0;
        
        items = new MarketItem[](unSoldItemCount);

        for (uint256 i = 0; i< totalItemCount ; i++) {
            if(_idMarketItem[i + 1].owner == _contractAddress) {
                uint256 currentId = i + 1;

                MarketItem storage currentItem = _idMarketItem[currentId];
                items[currentIndex] = currentItem;

                unchecked {
                    currentIndex += 1;
                }

            }
        }
        return items;
    }

    function fetchMyNFT() public view returns(MarketItem[] memory items) {
        uint256 totalCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i< totalCount; i++ ) {
            if (_idMarketItem[i+1].owner == msg.sender) {
                itemCount += 1;
            }
        }

        items = new MarketItem[](itemCount);
        for (uint256 i = 0; i< totalCount; i++) {
            if (_idMarketItem[i +1].owner == msg.sender) {
                uint256 currentId = i+ 1;
                MarketItem storage currentItem = _idMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function fetchItemListed() public view returns (MarketItem[] memory items) {
        uint256 totalCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i< totalCount; i++) {
            if (_idMarketItem[i + 1].seller == msg.sender) {
                itemCount += 1;

            }
        }

        items = new MarketItem[](itemCount); 
        for (uint256 i = 0; i< totalCount; i++) {
            if (_idMarketItem[i+ 1].seller == msg.sender) {
            
            uint256 currentId = i + 1;

            MarketItem storage currentItem = _idMarketItem[currentId];
            items[currentIndex] = currentItem;
            currentIndex += 1;
        }
        }
        return items;
    }

    function withdrawBalance() public nonReentrant onlyOwner {
        uint256 balance = _contractAddress.balance; 
        payable(owner).transfer(balance);       
    }
}


