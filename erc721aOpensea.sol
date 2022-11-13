// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
//pragma solidity ^0.8.4; antes era 0.8.4, lo baje para que fuera compatible con las nuevas funciones, pero no se si eso afecta al resto de las funciones.
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "openzeppelin/contracts/token/ERC721/ERC721.sol";
import {DefaultOperatorFilterer} from "../DefaultOperatorFilterer.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";


contract Nombre is ERC721A, DefaultOperatorFilterer, Ownable { //le agregue DefaultOperatorFilterer antes de Ownable
    using Strings for uint256;

    string public  baseTokenUri;
    string public  placeholderTokenUri;
    string public baseExtension = ".json";

    uint public tSupply = 10000;
    bool public revealed = true;
    bool public onlyWhitelist = false;
    bool public pause = false;

    uint public cost = 0 ether;
    mapping(address=>bool) public hasClaimed;
    mapping(address=>bool) public whitelisted;

    constructor(string memory _baseTokenURI, string memory _placeholderURI) ERC721A("Nombre", "YYY") {
        baseTokenUri = _baseTokenURI;
        placeholderTokenUri = _placeholderURI;
    }

    function paused(bool _val) external onlyOwner {
        pause = _val;
    }

    function onlyWhitelisted(bool _val) external onlyOwner{
        onlyWhitelist = _val;
    }

    function reveal(bool _val) external onlyOwner {
        revealed = _val;
    } 
    
    function mint(uint256 quantity) external payable{
        require(!pause, "contract is paused!");
        require(quantity != 0, "please increase quantity from zero!");
        require(totalSupply() + quantity <= tSupply, "exceding total supply");

        if (onlyWhitelist) {
            require(whitelisted[msg.sender], "not in whitelist");
             internalLogic(quantity);
        } else {
            internalLogic(quantity);
        }
    }

    function internalLogic(uint quantity) private {
        if(quantity == 1 && !hasClaimed[msg.sender]) {
            require(hasClaimed[msg.sender] == false, "already claimed");
            hasClaimed[msg.sender] = true;
            _mint(msg.sender, quantity);
        } else if (quantity == 1 && hasClaimed[msg.sender]) {
            require(msg.value >= cost, "not enough balance!");
            _mint(msg.sender, quantity);
        } else {
            if(hasClaimed[msg.sender] == false) {
            hasClaimed[msg.sender] = true;
            uint totalQToCalculate = quantity - 1;
            uint tCost = cost * totalQToCalculate;
            require(msg.value >= tCost, "not enough balance to mint!");
            _mint(msg.sender, quantity);
            } else {
                require(msg.value >= cost * quantity, "insufficient balance!");
                 _mint(msg.sender, quantity);
            }       
        }

    }

    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    
    if(revealed == false) {
        return placeholderTokenUri;
    }
    uint256 trueId = tokenId + 1;

    return bytes(baseTokenUri).length > 0
        ? string(abi.encodePacked(baseTokenUri, trueId.toString(), baseExtension))
        : "";
  }


  function setTokenUri(string memory _baseTokenUri) external onlyOwner {
        baseTokenUri = _baseTokenUri;
    }
    function setPlaceHolderUri(string memory _placeholderTokenUri) external onlyOwner {
        placeholderTokenUri = _placeholderTokenUri;
    }

    function addWhitelisted(address[] memory accounts) external onlyOwner {

    for (uint256 account = 0; account < accounts.length; account++) {
        whitelisted[accounts[account]] = true;
    }
}

    function withdraw() external payable onlyOwner {
    (bool os, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(os);
  }
  
  //desde aqui las nuevas funciones
  
  function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function tokenURI(uint256) public pure override returns (string memory) {
        return "";
    }
}