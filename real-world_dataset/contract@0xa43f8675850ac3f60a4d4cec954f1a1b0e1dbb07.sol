pragma solidity ^0.4.23;

library AZTECInterface {
    function validateJoinSplit(bytes32[6][], uint, uint, bytes32[4]) external pure returns (bool) {}
}

/**
 * @title Library to validate AZTEC zero-knowledge proofs
 * @author Zachary Williamson, AZTEC
 * @dev Don't include this as an internal library. This contract uses a static memory table to cache elliptic curve primitives and hashes.
 * Calling this internally from another function will lead to memory mutation and undefined behaviour.
 * The intended use case is to call this externally via `staticcall`. External calls to OptimizedAZTEC can be treated as pure functions as this contract contains no storage and makes no external calls (other than to precompiles)
 * Copyright Spilbury Holdings Ltd 2018. All rights reserved.
 * We will be releasing AZTEC as an open-source protocol that provides efficient transaction privacy for Ethereum.
 * This will include our bespoke AZTEC decentralized exchange, allowing for cross-asset transfers with full transaction privacy
 * and interopability with public decentralized exchanges.
 * Stay tuned for updates!
 **/
contract AZTEC {
    /**
     * @dev AZTEC will take any transaction sent to it and attempt to validate a zero knowledge proof.
     * If the proof is not valid, the transaction will throw.
     * @notice See AZTECInterface for how method calls should be constructed.
     * 'Cost' of raw elliptic curve primitives for a transaction: 260,700 gas + (124,500 * number of input notes) + (167,600 * number of output notes).
     * For a basic 'joinSplit' with 2 inputs and 2 outputs = 844,900 gas.
     * AZTEC is written in YUL to enable manual memory management and for other efficiency savings.
     **/
    function() external payable {
        assembly {

            // We don't check for function signatures, there's only one function that ever gets called: validateJoinSplit()
            // We still assume calldata is offset by 4 bytes so that we can represent this contract through a compatible ABI
            validateJoinSplit()

            // should not get here
            mstore(0x00, 404)
            revert(0x00, 0x20)

            /**
             * @dev Validate an AZTEC protocol JoinSplit zero-knowledge proof
             * Calldata Map is
             * 0x04:0x24       = calldata location of start of ```note``` dynamic array
             * 0x24:0x44       = m, which defines the index separator between input notes ando utput notes
             * 0x44:0x64       = Fiat-Shamir heuristicified random challenge
             * 0x64:0xe4       = G2 element t2, the trusted setup public key
             * 0xe4:0x104      = start of ```note``` dynamic array, contains the size of the array (```n```)
             * Subsequent calldata arranged in 0xc0 sized blocks of data, each representing an AZTEC commitment and zero-knowledge proof variables
             *
             * Note data map (uint[6]) is
             * 0x00:0x20       = Z_p element \bar{k}_i
             * 0x20:0x40       = Z_p element \bar{a}_i
             * 0x40:0x80       = G1 element \gamma_i
             * 0x80:0xc0       = G1 element \sigma_i
             *
             * The last element in the note array is special and contains the following:
             * 0x00:0x20       = Z_p element k_{public}
             * 0x20:0x40       = Z_p element \bar{a}_i
             * 0x40:0x60       = G1 element \gamma_i
             * 0x60-0x80       = G1 element \sigma_i
             * We can recover \bar{k}_{n-1} from the homomorphic sum condition \sum_{i=0}^{m-1}\bar{k}_i = \sum_{i=m}^{n-1}\bar{k}_i + k_{public}
             * So we use the empty slot to store k_{public}, which represents any public 'value' being blinded into zero-knowledge notes
             *
             * We use a hard-coded memory map to reduce gas costs - if this is not called as an external contract then terrible things will happen!
             * 0x00:0x20       = scratch data to store result of keccak256 calls
             * 0x20:0x80       = scratch data to store \gamma_i and a multiplication scalar
             * 0x80:0xc0       = x-coordinate of generator h
             * 0xc0:0xe0       = y-coordinate of generator h
             * 0xe0:0x100      = scratch data to store a scalar we plan to multiply h by
             * 0x100:0x160     = scratch data to store \sigma_i and a multiplication scalar
             * 0x160:0x1a0     = stratch data to store result of G1 point additions
             * 0x1a0:0x1c0     = scratch data to store result of \sigma_i^{-cx_{i-m-1}}
             * 0x1c0:0x200     = location of pairing accumulator \sigma_{acc}, where \sigma_{acc} = \prod_{i=m}^{n-1}\sigma_i^{cx_{i-m-1}}
             * 0x220:0x260     = scratch data to store \gamma_i^{cx_{i-m-1}}
             * 0x260:0x2a0     = location of pairing accumulator \gamma_{acc}, where \gamma_{acc} = \prod_{i=m}^{n-1}\gamma_i^{cx_{i-m-1}}
             * 0x2a0:0x2c0     = msg.sender (contract should be called via delegatecall/staticcall)
             * 0x2c0:0x2e0     = kn (memory used to reconstruct hash starts here)
             * 0x2e0:0x300     = m
             * 0x300:???       = block of memory that contains (\gamma_i, \sigma_i)_{i=0}^{n-1} concatenated with (B_i)_{i=0}^{n-1}
             **/
            function validateJoinSplit() {
                mstore(0x80, 7673901602397024137095011250362199966051872585513276903826533215767972925880) // h_x
                mstore(0xa0, 8489654445897228341090914135473290831551238522473825886865492707826370766375) // h_y
                let notes := add(0x04, calldataload(0x04))
                let m := calldataload(0x24)
                let n := calldataload(notes)
                let gen_order := 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001
                let challenge := mod(calldataload(0x44), gen_order)

                // validate m <= n
                if gt(m, n) { mstore(0x00, 404) revert(0x00, 0x20) }

                // recover k_{public} and calculate k_{public}
                let kn := calldataload(sub(calldatasize, 0xc0))

                // add kn and m to final hash table
                mstore(0x2a0, caller)
                mstore(0x2c0, kn)
                mstore(0x2e0, m)
                kn := mulmod(sub(gen_order, kn), challenge, gen_order) // we actually want c*k_{public}
                hashCommitments(notes, n)
                let b := add(0x300, mul(n, 0x80))

                // Iterate over every note and calculate the blinding factor B_i = \gamma_i^{kBar}h^{aBar}\sigma_i^{-c}.
                // We use the AZTEC protocol pairing optimization to reduce the number of pairing comparisons to 1, which adds some minor alterations
                for { let i := 0 } lt(i, n) { i := add(i, 0x01) } {

                    // Get the calldata index of this note
                    let noteIndex := add(add(notes, 0x20), mul(i, 0xc0))

                    // Define variables k, a and c.
                    // If i <= m then
                    //   k = kBar_i
                    //   a = aBar_i
                    //   c = challenge
                    // If i > m then we add a modification for the pairing optimization
                    //   k = kBar_i * x_i
                    //   a = aBar_i * x_i
                    //   c = challenge * x_i
                    // Set j = i - (m + 1).
                    // x_0 = 1
                    // x_1 = keccak256(input string)
                    // all other x_{j} = keccak256(x_{j-1})
                    // The reason for doing this is that the point  \sigma_i^{-cx_j} can be re-used in the pairing check
                    // Instead of validating e(\gamma_i, t_2) == e(\sigma_i, g_2) for all i = [m+1,\ldots,n]
                    // We instead validate e(\Pi_{i=m+1}^{n}\gamma_i^{-cx_j}, t_2) == e(\Pi_{i=m+1}^{n}\sigma_i^{cx_j}, g_2).
                    // x_j is a pseudorandom variable whose entropy source is the input string, allowing for
                    // a sum of commitment points to be evaluated in one pairing comparison
                    let k
                    let a := calldataload(add(noteIndex, 0x20))
                    let c := challenge

                    // We don't transmit kBar_{n-1} in the proof to save space, instead we derive it
                    // As per the homomorphic sum condition: \sum_{i=0}^{m-1}\bar{k}_i = \sum_{i=m}^{n-1}\bar{k}_i + k_{public}c, 
                    // We can recover \bar{k}_{n-1}.
                    // If m=n then \bar{k}_{n-1} = \sum_{i=0}^{n-1}\bar{k}_i + k_{public}
                    // else \bar{k}_{n-1} = \sum_{i=0}^{m-1}\bar{k}_i - \sum_{i=m}^{n-1}\bar{k}_i - k_{public}
                    switch eq(add(i, 0x01), n)
                    case 1 {
                        k := kn

                        // if all notes are input notes, invert k
                        if eq(m, n) {
                            k := sub(gen_order, k)
                        }
                    }
                    case 0 { k := calldataload(noteIndex) }

                    // Check this commitment is well formed...
                    validateCommitment(noteIndex, k, a)

                    // If i > m then this is an output note.
                    // Set k = kx_j, a = ax_j, c = cx_j, where j = i - (m+1)
                    switch gt(add(i, 0x01), m)
                    case 1 {

                        // before we update k, update kn = \sum_{i=0}^{m-1}k_i - \sum_{i=m}^{n-1}k_i
                        kn := addmod(kn, sub(gen_order, k), gen_order)
                        let x := mod(mload(0x00), gen_order)
                        k := mulmod(k, x, gen_order)
                        a := mulmod(a, x, gen_order)
                        c := mulmod(challenge, x, gen_order)

                        // calculate x_{j+1}
                        mstore(0x00, keccak256(0x00, 0x20))
                    }
                    case 0 {

                        // nothing to do here except update kn = \sum_{i=0}^{m-1}k_i - \sum_{i=m}^{n-1}k_i
                        kn := addmod(kn, k, gen_order)
                    }
                    
                    // Calculate the G1 element \gamma_i^{k}h^{a}\sigma_i^{-c} = B_i
                    // Memory map:
                    // 0x20: \gamma_iX
                    // 0x40: \gamma_iY
                    // 0x60: k_i
                    // 0x80: hX
                    // 0xa0: hY
                    // 0xc0: a_i
                    // 0xe0: \sigma_iX
                    // 0x100: \sigma_iY
                    // 0x120: -c
                    calldatacopy(0xe0, add(noteIndex, 0x80), 0x40)
                    calldatacopy(0x20, add(noteIndex, 0x40), 0x40)
                    mstore(0x120, sub(gen_order, c)) 
                    mstore(0x60, k)
                    mstore(0xc0, a)

                    // Call bn128 scalar multiplication precompiles
                    // Represent point + multiplication scalar in 3 consecutive blocks of memory
                    // Store \sigma_i^{-c} at 0x1a0:0x200
                    // Store \gamma_i^{k} at 0x120:0x160
                    // Store h^{a} at 0x160:0x1a0
                    let result := staticcall(gas, 7, 0xe0, 0x60, 0x1a0, 0x40)
                    result := and(result, staticcall(gas, 7, 0x20, 0x60, 0x120, 0x40))
                    result := and(result, staticcall(gas, 7, 0x80, 0x60, 0x160, 0x40))

                    // Call bn128 group addition precompiles
                    // \gamma_i^{k} and h^{a} in memory block 0x120:0x1a0
                    // Store result of addition at 0x160:0x1a0
                    result := and(result, staticcall(gas, 6, 0x120, 0x80, 0x160, 0x40))

                    // \gamma_i^{k}h^{a} and \sigma^{-c} in memory block 0x160:0x1e0
                    // Store resulting point B at memory index b
                    result := and(result, staticcall(gas, 6, 0x160, 0x80, b, 0x40))

                    // We have \sigma^{-c} at 0x1a0:0x200
                    // And \sigma_{acc} at 0x1e0:0x200
                    // If i = m + 1 (i.e. first output note)
                    // then we set \gamma_{acc} and \sigma_{acc} to \gamma_i, -\sigma_i
                    if eq(i, m) {
                        mstore(0x260, mload(0x20))
                        mstore(0x280, mload(0x40))
                        mstore(0x1e0, mload(0xe0))
                        mstore(0x200, sub(0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47, mload(0x100)))
                    }

                    // If i > m + 1 (i.e. subsequent output notes)
                    // then we add \sigma^{-c} and \sigma_{acc} and store result at \sigma_{acc} (0x1e0:0x200)
                    // we then calculate \gamma^{cx} and add into \gamma_{acc}
                    if gt(i, m) {
                       mstore(0x60, c)
                       result := and(result, staticcall(gas, 7, 0x20, 0x60, 0x220, 0x40))

                       // \gamma_i^{cx} now at 0x220:0x260, \gamma_{acc} is at 0x260:0x2a0
                       result := and(result, staticcall(gas, 6, 0x220, 0x80, 0x260, 0x40))

                       // add \sigma_i^{-cx} and \sigma_{acc} into \sigma_{acc} at 0x1e0
                       result := and(result, staticcall(gas, 6, 0x1a0, 0x80, 0x1e0, 0x40))
                    }

                    // throw transaction if any calls to precompiled contracts failed
                    if iszero(result) { mstore(0x00, 400) revert(0x00, 0x20) }
                    b := add(b, 0x40) // increase B pointer by 2 words
                }

                // If the AZTEC protocol is implemented correctly then any input notes were previously outputs of
                // a JoinSplit transaction. We can inductively assume that all input notes are well-formed AZTEC commitments and do not need to validate the implicit range proof
                // This is not the case for any output commitments, so if (m < n) call validatePairing()
                if lt(m, n) {
                   validatePairing(0x64)
                }

                // We now have the note commitments and the calculated blinding factors in a block of memory
                // starting at 0x2a0, of size (b - 0x2a0).
                // Hash this block to reconstruct the initial challenge and validate that they match
                let expected := mod(keccak256(0x2a0, sub(b, 0x2a0)), gen_order)
                if iszero(eq(expected, challenge)) {

                    // No! Bad! No soup for you!
                    mstore(0x00, 404)
                    revert(0x00, 0x20)
                }

                // Great! All done. This is a valid proof so return ```true```
                mstore(0x00, 0x01)
                return(0x00, 0x20)
            }

            /**        
             * @dev evaluate if e(P1, t2) . e(P2, g2) == 0.
             * @notice we don't hard-code t2 so that contracts that call this library can use different trusted setups.
             **/
            function validatePairing(t2) {
                let field_order := 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
                let t2_x_1 := calldataload(t2)
                let t2_x_2 := calldataload(add(t2, 0x20))
                let t2_y_1 := calldataload(add(t2, 0x40))
                let t2_y_2 := calldataload(add(t2, 0x60))

                // check provided setup pubkey is not zero or g2
                if or(or(or(or(or(or(or(
                    iszero(t2_x_1),
                    iszero(t2_x_2)),
                    iszero(t2_y_1)),
                    iszero(t2_y_2)),
                    eq(t2_x_1, 0x1800deef121f1e76426a00665e5c4479674322d4f75edadd46debd5cd992f6ed)),
                    eq(t2_x_2, 0x198e9393920d483a7260bfb731fb5d25f1aa493335a9e71297e485b7aef312c2)),
                    eq(t2_y_1, 0x12c85ea5db8c6deb4aab71808dcb408fe3d1e7690c43d37b4ce6cc0166fa7daa)),
                    eq(t2_y_2, 0x90689d0585ff075ec9e99ad690c3395bc4b313370b38ef355acdadcd122975b))
                {
                    mstore(0x00, 400)
                    revert(0x00, 0x20)
                }

                // store coords in memory
                // indices are a bit off, scipr lab's libff limb ordering (c0, c1) is opposite to what precompile expects
                // We can overwrite the memory we used previously as this function is called at the end of the validation routine.
                mstore(0x20, mload(0x1e0)) // sigma accumulator x
                mstore(0x40, mload(0x200)) // sigma accumulator y
                mstore(0x80, 0x1800deef121f1e76426a00665e5c4479674322d4f75edadd46debd5cd992f6ed)
                mstore(0x60, 0x198e9393920d483a7260bfb731fb5d25f1aa493335a9e71297e485b7aef312c2)
                mstore(0xc0, 0x12c85ea5db8c6deb4aab71808dcb408fe3d1e7690c43d37b4ce6cc0166fa7daa)
                mstore(0xa0, 0x90689d0585ff075ec9e99ad690c3395bc4b313370b38ef355acdadcd122975b)
                mstore(0xe0, mload(0x260)) // gamma accumulator x
                mstore(0x100, mload(0x280)) // gamma accumulator y
                mstore(0x140, t2_x_1)
                mstore(0x120, t2_x_2)
                mstore(0x180, t2_y_1)
                mstore(0x160, t2_y_2)

                let success := staticcall(gas, 8, 0x20, 0x180, 0x20, 0x20)

                if or(iszero(success), iszero(mload(0x20))) {
                    mstore(0x00, 400)
                    revert(0x00, 0x20)
                }
            }

            /**
             * @dev check that this note's points are on the altbn128 curve(y^2 = x^3 + 3)
             * and that signatures 'k' and 'a' are modulo the order of the curve. Transaction will throw if this is not the case.
             * @param note the calldata loation of the note
             **/
            function validateCommitment(note, k, a) {
                let gen_order := 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001
                let field_order := 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
                let gammaX := calldataload(add(note, 0x40))
                let gammaY := calldataload(add(note, 0x60))
                let sigmaX := calldataload(add(note, 0x80))
                let sigmaY := calldataload(add(note, 0xa0))
                if iszero(
                    and(
                        and(
                            and(
                                eq(mod(a, gen_order), a), // a is modulo generator order?
                                gt(a, 1)                  // can't be 0 or 1 either!
                            ),
                            and(
                                eq(mod(k, gen_order), k), // k is modulo generator order?
                                gt(k, 1)                  // and not 0 or 1
                            )
                        ),
                        and(
                            eq( // y^2 ?= x^3 + 3
                                addmod(mulmod(mulmod(sigmaX, sigmaX, field_order), sigmaX, field_order), 3, field_order),
                                mulmod(sigmaY, sigmaY, field_order)
                            ),
                            eq( // y^2 ?= x^3 + 3
                                addmod(mulmod(mulmod(gammaX, gammaX, field_order), gammaX, field_order), 3, field_order),
                                mulmod(gammaY, gammaY, field_order)
                            )
                        )
                    )
                ) {
                    mstore(0x00, 400)
                    revert(0x00, 0x20)
                }
            }

            /**
             * @dev Calculate the keccak256 hash of the commitments for both input notes and output notes.
             * This is used both as an input to validate the challenge `c` and also to generate pseudorandom relationships
             * between commitments for different outputNotes, so that we can combine them into a single multi-exponentiation for the purposes of validating the bilinear pairing relationships.
             * @param notes calldata location notes
             * @param n number of notes
             **/
            function hashCommitments(notes, n) {
                for { let i := 0 } lt(i, n) { i := add(i, 0x01) } {
                    let index := add(add(notes, mul(i, 0xc0)), 0x60)
                    calldatacopy(add(0x300, mul(i, 0x80)), index, 0x80)
                }
                mstore(0x00, keccak256(0x300, mul(n, 0x80)))
            }
        }
    }
}
