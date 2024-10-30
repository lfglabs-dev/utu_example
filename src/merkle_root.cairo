use utils::hash::Digest;
use utils::double_sha256::double_sha256_parent;

/// Computes the Merkle root from a transaction hash and its siblings.
///
/// # Arguments
/// * `tx_hash` - The transaction hash as a Digest
/// * `siblings` - An array of tuples (Digest, bool), where the bool indicates if the sibling is on
/// the right
///
/// # Returns
/// The computed Merkle root as a Digest
pub fn compute_merkle_root(tx_hash: Digest, siblings: Array<(Digest, bool)>) -> Digest {
    let mut current_hash = tx_hash;

    // Iterate through all siblings
    let mut i = 0;
    loop {
        if i == siblings.len() {
            break;
        }

        let (sibling, is_left) = *siblings.at(i);

        // Concatenate current_hash and sibling based on the order
        current_hash =
            if is_left {
                double_sha256_parent(@sibling, @current_hash)
            } else {
                double_sha256_parent(@current_hash, @sibling)
            };

        i += 1;
    };

    current_hash
}

#[cfg(test)]
mod tests {
    use super::compute_merkle_root;
    use utils::hex::{hex_to_hash_rev};

    #[test]
    fn test_compute_merkle_root() {
        // Test data
        let tx_hash = hex_to_hash_rev(
            "4ff32a7e58200897220ce4615e30e3e414991222d7eda27e693116abea8b8f33"
        );
        let siblings = array![
            (
                hex_to_hash_rev("8bfa0f7edb3caa2a3e8e028cf5fa196d078e6f9d7b9f2699f79f28bb181f8566"),
                true
            ),
            (
                hex_to_hash_rev("8a5d61f4ba10158897cce12d0224112e7471c001ff787cd0678b9283140a6bc6"),
                true
            ),
            (
                hex_to_hash_rev("c2c314fd9e672b70e9b8463a542fbc97400e3bed8702ebf0227d9725e7a8a120"),
                true
            ),
            (
                hex_to_hash_rev("568eaa8a3c36b3123abc0d28fbc9a6db7bbf8f42158d44e3b747762354378dda"),
                false
            ),
            (
                hex_to_hash_rev("2675bcd84c5bcb94ead1ffc9986f7c011bac7fc9af3504d9769a949a76ae9026"),
                true
            ),
            (
                hex_to_hash_rev("81c29c6d2d2841c1230817a968e1260185f064131dbbbd415be570e55582b097"),
                false
            ),
        ];

        let expected_merkle_root = hex_to_hash_rev(
            "a25a937478ca5f18e77aef1cdb9e69e347288248411253faefcd04d90b4c9380"
        );
        let computed_merkle_root = compute_merkle_root(tx_hash, siblings);

        assert(computed_merkle_root == expected_merkle_root, 'Incorrect Merkle root');
    }
}
