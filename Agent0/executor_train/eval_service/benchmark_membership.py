import timeit

def benchmark():
    keys = ["model", "api_key", "num_models", "host", "port", "other_key1", "other_key2"]

    list_literal = ["model", "api_key", "num_models", "host", "port"]
    set_literal = {"model", "api_key", "num_models", "host", "port"}

    def test_list():
        for k in keys:
            if k not in list_literal:
                pass

    def test_set():
        for k in keys:
            if k not in set_literal:
                pass

    n = 1000000
    list_time = timeit.timeit(test_list, number=n)
    set_time = timeit.timeit(test_set, number=n)

    print(f"List membership test time ({n} iterations): {list_time:.6f} seconds")
    print(f"Set membership test time ({n} iterations): {set_time:.6f} seconds")
    print(f"Improvement: {(list_time - set_time) / list_time * 100:.2f}%")

if __name__ == "__main__":
    benchmark()
