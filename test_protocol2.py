import torch
import numpy as np
from tensordict import TensorDict

import sys
sys.path.append("Agent0/curriculum_train")
from verl.protocol import DataProto as DataProtoCurriculum

sys.path.remove("Agent0/curriculum_train")
sys.path.append("Agent0/executor_train/verl")
from verl.protocol import DataProto as DataProtoExecutor

def test_lift_restriction(DataProtoClass):
    # Test removing the restriction specifically on non_tensor_batch
    # when num_batch_dims > 1

    # We first create it with batch_size of length 2 and see if we can bypass it
    batch = TensorDict({"a": torch.randn(2, 3, 4)}, batch_size=(2, 3))
    non_tensor_batch = {"b": np.random.randn(2, 3, 5)}

    try:
        DataProtoClass(batch=batch, non_tensor_batch=non_tensor_batch)
    except Exception as e:
        print(f"Failed with exception: {type(e).__name__}: {e}")

print("Curriculum train:")
test_lift_restriction(DataProtoCurriculum)
print("Executor train:")
test_lift_restriction(DataProtoExecutor)
