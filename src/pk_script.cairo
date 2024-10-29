use utils::double_sha256::double_sha256_byte_array;

// Tt's a very unoptimized code which computes the target Bitcoin address from a p2pkh
// script. In production you probably just want to assert the public key is yours and not
// compute the human readable address, but it looks better for the example
pub fn extract_p2pkh_target(script: @ByteArray) -> ByteArray {
    assert(script[0] == 0x76, 'wrong p2pkh prefix');
    assert(script[1] == 0xa9, 'wrong p2pkh prefix');

    let script_length = script.len();
    // third byte is pub_key_hash_length
    let pub_key_hash_length = script[2].into();
    assert(script_length == pub_key_hash_length + 5, 'wrong script length');
    let mut i = 3;
    let stop = i + pub_key_hash_length;
    let mut address: ByteArray = Default::default();
    // we append the version byte
    address.append_byte(0x00);
    // we add the pub key hash
    loop {
        if i == stop {
            break;
        }
        address.append_byte(script[i]);
        i += 1;
    };
    // finally we add the checksum
    let hashed: ByteArray = double_sha256_byte_array(@address).into();
    address.append_byte(hashed[0]);
    address.append_byte(hashed[1]);
    address.append_byte(hashed[2]);
    address.append_byte(hashed[3]);

    // and assert the suffix is correct
    assert(script[i] == 0x88, 'wrong p2pkh suffix');
    assert(script[i + 1] == 0xac, 'wrong p2pkh suffix');

    return base58_encode(@address);
}

// again, a very unoptimized code to perform a base54 encoding
fn base58_encode(input: @ByteArray) -> ByteArray {
    let mut result: ByteArray = Default::default();
    let mut num: u256 = 0;
    let mut i = 0;
    let input_len = input.len();

    // Convert bytes to number
    loop {
        if i == input_len {
            break;
        }
        num = num * 256;
        num += input[i].into();
        i += 1;
    };

    // Convert number to base58 string
    let alphabet: @ByteArray = @"123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";
    let mut temp: ByteArray = Default::default();

    loop {
        if num == 0 {
            break;
        }
        let (q, r) = DivRem::div_rem(num, 58);
        let idx: usize = r.try_into().unwrap();
        temp.append_byte(alphabet[idx]);
        num = q;
    };

    // Add leading zeros from input
    i = 0;
    loop {
        if i >= input_len {
            break;
        }
        if input.at(i).unwrap() != 0 {
            break;
        }
        temp.append_byte('1');
        i += 1;
    };

    // Reverse the string
    let temp_len = temp.len();
    let mut j = 0;
    loop {
        if j >= temp_len {
            break;
        }
        result.append_byte(temp.at(temp_len - 1 - j).unwrap());
        j += 1;
    };

    result
}
