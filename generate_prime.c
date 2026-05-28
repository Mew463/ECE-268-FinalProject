#include <iostream>
#include <random>
#include <cstdint>

using namespace std;

// ============================================================
// MODULAR EXPONENTIATION
// ============================================================

uint64_t modular_pow(
    uint64_t base,
    uint64_t exponent,
    uint64_t mod)
{
    uint64_t result = 1;

    base %= mod;

    while (exponent > 0)
    {
        if (exponent & 1)
        {
            result = (__uint128_t)result * base % mod;
        }

        base = (__uint128_t)base * base % mod;

        exponent >>= 1;
    }

    return result;
}

// ============================================================
// MILLER-RABIN PRIMALITY TEST
// ============================================================

bool is_prime(uint64_t n, int k = 10)
{
    if (n < 2)
        return false;

    if (n == 2 || n == 3)
        return true;

    if (n % 2 == 0)
        return false;

    // write n - 1 as d * 2^r
    uint64_t d = n - 1;
    int r = 0;

    while ((d & 1) == 0)
    {
        d >>= 1;
        r++;
    }

    random_device rd;
    mt19937_64 gen(rd());

    uniform_int_distribution<uint64_t>
        dist(2, n - 2);

    for (int i = 0; i < k; i++)
    {
        uint64_t a = dist(gen);

        uint64_t x =
            modular_pow(a, d, n);

        if (x == 1 || x == n - 1)
            continue;

        bool probably_prime = false;

        for (int j = 0; j < r - 1; j++)
        {
            x = modular_pow(x, 2, n);

            if (x == n - 1)
            {
                probably_prime = true;
                break;
            }
        }

        if (!probably_prime)
            return false;
    }

    return true;
}

// ============================================================
// GENERATE LARGE PRIME
// ============================================================

uint64_t generate_large_prime(int bits = 32)
{
    random_device rd;
    mt19937_64 gen(rd());

    uint64_t min =
        (1ULL << (bits - 1));

    uint64_t max =
        (1ULL << bits) - 1;

    uniform_int_distribution<uint64_t>
        dist(min, max);

    while (true)
    {
        uint64_t num = dist(gen);

        // force odd
        num |= 1ULL;

        // ensure highest bit set
        num |= (1ULL << (bits - 1));

        if (is_prime(num))
        {
            return num;
        }
    }
}

// ============================================================
// MAIN
// ============================================================

int main()
{
    uint64_t prime =
        generate_large_prime(32);

    cout << "Generated Prime:\n";
    cout << prime << endl;

    return 0;
}