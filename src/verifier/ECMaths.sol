/*
MIT License

Copyright (c) 2018 Lionello Lunesu

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.*/

// Ported from Solidity v0.8.4 to v0.8.13
pragma solidity ^0.8.13;

contract ModExp {
    // address constant MODEXP_BUILTIN = 0x0000000000000000000000000000000000000005;

    function modexp(uint256 b, uint256 e, uint256 m) internal view returns (uint256 result) {
        assembly {
            let freemem := mload(0x40)
            mstore(freemem, 0x20)
            mstore(add(freemem, 0x20), 0x20)
            mstore(add(freemem, 0x40), 0x20)
            mstore(add(freemem, 0x60), b)
            mstore(add(freemem, 0x80), e)
            mstore(add(freemem, 0xA0), m)
            let _ := call(39240, 0x0000000000000000000000000000000000000005, 0, freemem, 0xC0, freemem, 0x20)
            result := mload(freemem)
        }
    }
}

// Library for secp256r1, forked from https://github.com/tls-n/tlsnutils/blob/master/contracts/ECMath.sol
contract ECMath is ModExp {
    //curve parameters secp256r1
    uint256 constant A = 115792089210356248762697446949407573530086143415290314195533631308867097853948;
    uint256 constant B = 41058363725152142129326129780047268409114441015993725554835256314039467401291;
    uint256 constant GX = 48439561293906451759052585252797914202762949526041747995844080717082404635286;
    uint256 constant GY = 36134250956749795798585127919587881956611106672985015071877198253568414405109;
    uint256 constant P = 115792089210356248762697446949407573530086143415290314195533631308867097853951;
    uint256 constant N = 115792089210356248762697446949407573529996955224135760342422259061068512044369;
    uint256 constant H = 1;

    function verify(uint256 qx, uint256 qy, uint256 e, uint256 r, uint256 s) public view returns (bool) {
        uint256 w = invmod(s, N);
        uint256 u1 = mulmod(e, w, N);
        uint256 u2 = mulmod(r, w, N);

        uint256[3] memory comb = calcPointShamir(u1, u2, qx, qy);

        uint256 zInv2 = modexp(comb[2], P - 3, P);
        uint256 x = mulmod(comb[0], zInv2, P); // JtoA(comb)[0];
        return r == x;
    }

    function recover(uint256 e, uint8 v, uint256 r, uint256 s) public view returns (uint256[2]) {
        uint256 eInv = N - e;
        uint256 rInv = invmod(r, N);
        uint256 srInv = mulmod(rInv, s, N);
        uint256 eInvrInv = mulmod(rInv, eInv, N);

        uint256 ry = decompressPoint(r, v);
        uint256[3] memory q = calcPointShamir(eInvrInv, srInv, r, ry);

        return JtoA(q);
    }

    function calcPointShamir(uint256 u1, uint256 u2, uint256 qx, uint256 qy) private pure returns (uint256[3] R) {
        uint256[3] memory G = [GX, GY, 1];
        uint256[3] memory Q = [qx, qy, 1];
        uint256[3] memory Z = ecadd(Q, G);

        uint256 mask = 2 ** 255;

        // Skip leading zero bits
        uint256 or = u1 | u2;
        while (or & mask == 0) {
            mask = mask / 2;
        }

        // Initialize output
        if (u1 & mask != 0) {
            if (u2 & mask != 0) {
                R = Z;
            } else {
                R = G;
            }
        } else {
            R = Q;
        }

        while (true) {
            mask = mask / 2;
            if (mask == 0) {
                break;
            }

            R = ecdouble(R);

            if (u1 & mask != 0) {
                if (u2 & mask != 0) {
                    R = ecadd(Z, R);
                } else {
                    R = ecadd(G, R);
                }
            } else {
                if (u2 & mask != 0) {
                    R = ecadd(Q, R);
                }
            }
        }
    }

    function getSqrY(uint256 x) private pure returns (uint256) {
        //return y^2=x^3+Ax+B
        return addmod(mulmod(x, mulmod(x, x, P), P), addmod(mulmod(A, x, P), B, P), P);
    }

    //function checks if point (x, y) is on curve, x and y affine coordinate parameters
    function isPoint(uint256 x, uint256 y) public pure returns (bool) {
        //point fulfills y^2=x^3+Ax+B?
        return mulmod(y, y, P) == getSqrY(x);
    }

    function decompressPoint(uint256 x, uint8 yBit) private view returns (uint256) {
        //return sqrt(x^3+Ax+B)
        uint256 absy = modexp(getSqrY(x), 1 + (P - 3) / 4, P);
        return yBit == 0 ? absy : -absy;
    }

    // point addition for elliptic curve in jacobian coordinates
    // formula from https://en.wikibooks.org/wiki/Cryptography/Prime_Curve/Jacobian_Coordinates
    function ecadd(uint256[3] _p, uint256[3] _q) private pure returns (uint256[3] R) {
        // if (_q[0] == 0 && _q[1] == 0 && _q[2] == 0) {
        // 	return _p;
        // }

        uint256 z2 = mulmod(_q[2], _q[2], P);
        uint256 u1 = mulmod(_p[0], z2, P);
        uint256 s1 = mulmod(_p[1], mulmod(z2, _q[2], P), P);
        z2 = mulmod(_p[2], _p[2], P);
        uint256 u2 = mulmod(_q[0], z2, P);
        uint256 s2 = mulmod(_q[1], mulmod(z2, _p[2], P), P);

        if (u1 == u2) {
            if (s1 != s2) {
                //return point at infinity
                return [uint256(1), 1, 0];
            } else {
                return ecdouble(_p);
            }
        }

        u2 = addmod(u2, P - u1, P);
        z2 = mulmod(u2, u2, P);
        uint256 t2 = mulmod(u1, z2, P);
        z2 = mulmod(u2, z2, P);
        s2 = addmod(s2, P - s1, P);
        R[0] = addmod(addmod(mulmod(s2, s2, P), P - z2, P), P - mulmod(2, t2, P), P);
        R[1] = addmod(mulmod(s2, addmod(t2, P - R[0], P), P), P - mulmod(s1, z2, P), P);
        R[2] = mulmod(u2, mulmod(_p[2], _q[2], P), P);
    }

    //point doubling for elliptic curve in jacobian coordinates
    //formula from https://en.wikibooks.org/wiki/Cryptography/Prime_Curve/Jacobian_Coordinates
    function ecdouble(uint256[3] _p) private pure returns (uint256[3] R) {
        if (_p[1] == 0) {
            //return point at infinity
            return [uint256(1), 1, 0];
        }

        uint256 z2 = mulmod(_p[2], _p[2], P);
        uint256 m = addmod(mulmod(A, mulmod(z2, z2, P), P), mulmod(3, mulmod(_p[0], _p[0], P), P), P);
        uint256 y2 = mulmod(_p[1], _p[1], P);
        uint256 s = mulmod(4, mulmod(_p[0], y2, P), P);

        R[0] = addmod(mulmod(m, m, P), P - mulmod(s, 2, P), P);
        R[2] = mulmod(2, mulmod(_p[1], _p[2], P), P); // consider R might alias _p
        R[1] = addmod(mulmod(m, addmod(s, P - R[0], P), P), P - mulmod(8, mulmod(y2, y2, P), P), P);
    }

    //jacobian to affine coordinates transformation
    function JtoA(uint256[3] p) private view returns (uint256[2] Pnew) {
        uint256 zInv = invmod(p[2], P);
        uint256 zInv2 = mulmod(zInv, zInv, P);
        Pnew[0] = mulmod(p[0], zInv2, P);
        Pnew[1] = mulmod(p[1], mulmod(zInv, zInv2, P), P);
    }

    //computing inverse by using fermat's theorem
    function invmod(uint256 _a, uint256 _p) private view returns (uint256 invA) {
        invA = modexp(_a, _p - 2, _p);
    }
}
