 // SPDX-License-Identifier: MIT
 pragma solidity ^0.8.20;

 contract ProofAnchor {
     event Anchored(bytes32 indexed root, uint256 timestamp);

     function anchor(bytes32 root) external {
         emit Anchored(root, block.timestamp);
     }
 }
