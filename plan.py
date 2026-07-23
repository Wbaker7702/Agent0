import sys
import torch
import numpy as np

def run():
    print("Plan is simple:")
    print("1. Remove `assert len(self.batch.batch_size) == 1` in `check_consistency` in both protocol.py files")
    print("2. Remove `assert num_batch_dims == 1` in `from_dict` in both protocol.py files")
    print("3. In `check_consistency`, instead of `len(value) == batch_size`, do `value.shape[:len(self.batch.batch_size)] == self.batch.batch_size` or something similar.")

if __name__ == "__main__":
    run()
