# Troubleshooting

## Setup did not finish

Read the setup log: `sudo cat /var/log/brev-workspace.log`. First start downloads the model and the sandbox image. The lab service waits up to 30 minutes for the model server to list `coder` before it reports a failure.

## The open-code-server link shows an error

- `systemctl status code-server-lab.service`
- `curl -fsS http://localhost:13337/healthz`

## The terminal does not open the agent

- `openshell sandbox list` should show `kernel-lab` as Ready or Running.
- `sudo systemctl restart kernel-lab.service` re-creates the sandbox if it is gone.

## The model does not answer

- `sudo docker logs --tail 100 vllm`
- `curl -fsS http://localhost:8000/v1/models` should list `coder`.
- If vLLM ran out of memory, redeploy with MAX_MODEL_LEN set to 32768.

## bench.py exits with code 3

Another process kept the GPU above 5 percent utilization while the harness sampled it. Wait for the agent's model call to finish, check `nvidia-smi`, and run it again.

## Nsight Compute reports no counters

Some instances restrict GPU performance counters to administrators. Nsight Systems and compute-sanitizer still work; the report shows the Nsight Compute column as unavailable.

## After Stop and Start

Services return on their own: vLLM (restart policy), `kernel-lab.service`, `kernel-report.service` and `code-server-lab.service`. The public IP can change; Secure Links follow it.
