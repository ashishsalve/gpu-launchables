# Two tasks to try

Paste each task into a new Hermes chat.

## 1. Browse the web

```
Open https://github.com/ggml-org/llama.cpp/releases and summarise what changed in the three newest releases. Give each release tag and its link.
```

Check the answer against the releases page: it should name three release tags, summarise each and link to it.

## 2. Run terminal commands

```
Clone https://github.com/more-itertools/more-itertools at tag v11.2.1 into ~/work, install it with pip in a virtual environment, run its test suite and tell me how many tests passed and which failed.
```

The commands run inside the hermes container. more-itertools is a small pure-Python library under the MIT License.

## Check that the model is local

- Hermes is configured to send its model calls to the llama.cpp server in this stack, `http://llama:8080/v1`.
- On the instance, run this before and after a task:

  ```
  curl -s http://127.0.0.1:8080/metrics | grep -E '^llamacpp:(prompt_tokens_total|tokens_predicted_total)'
  ```

  It prints llama.cpp's prompt and generated token counters. Both counters rise while the agent works.
- `nvidia-smi` shows the processes using the GPU.
- Port 8080 is published on the instance loopback only. The Launchable's one Secure Link, `open-hermes`, is for the dashboard port 9119.
