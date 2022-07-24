// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract staking {

    mapping(uint256 => string) internal idToUri;

    constructor() ERC721("NFT721", "NFTT") {
        mint(msg.sender, 1, "https://ipfs.io/ipfs/QmSaT4LGDajYz7E8471LfHu342JkNcS73ewkxH3vBr6cXF?filename=metaSimpsonNFT.json");
        tokenURI(1);
    }

    function mint(address _to, uint256 _tokenId, string memory _uri) public {
        _safeMint(_to, _tokenId);
        idToUri[_tokenId] = _uri;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        return idToUri[_tokenId];
    }
}

