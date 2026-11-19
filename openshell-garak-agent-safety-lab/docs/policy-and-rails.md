# Policy and rails

## OpenShell sandbox policy

File: `~/workspace/asl/config/openshell/policy.yaml`.

- Filesystem: read-only `/usr`, `/lib`, `/etc`, `/lab/app`; read-write `/tmp`, `/lab/data`.
- Network: one allowed endpoint, the host name OpenShell provides inside the sandbox for reaching the host, port 9004. Everything else is denied, including the attacker sink on port 9200, so an exfiltration attempt from the sandboxed agent shows up as a denial row.
- The sandbox gets its own copy of the lab data folder (`FAKE_API_KEY.txt` and `faq.txt`) at start, so the sandboxed lane faces the same canary as the other lanes.

Filesystem rules apply when the sandbox is created. Network rules can change while it runs. When you save the policy in the lab, the lab runs this command for you and shows whether it succeeded:

```
openshell policy set asl-agent --policy ~/workspace/asl/config/openshell/policy.yaml --wait
```

## Guarded inference route

vLLM and NeMo Guardrails listen on localhost only. A small relay listens on the host address that the OpenShell host name resolves to inside the sandbox, port 9004, and forwards only `POST /v1/chat/completions` and `GET /v1/models` to NeMo Guardrails. No model port is opened beyond localhost.

## NeMo Guardrails config

File: `~/workspace/asl/config/guardrails/config.yml`.

- Main model: `lightning` from the local vLLM.
- Input rails: `jailbreak detection model` (the NemoGuard JailbreakDetect classifier on CPU, endpoint `http://jailbreak-detect:1337/model`) and `self check input`.
- Output rail: `self check output`.
- With `GUARD_PROFILE=jailbreak+content-safety`, Nemotron 3.5 Content Safety input and output rails are added.

When you save the guardrails config in the lab, the lab restarts the NeMo Guardrails container and shows whether it succeeded. The output of the last apply is in `~/workspace/asl/config/.apply-policy.log` and `.apply-guardrails.log`. Once the lab reports Applied, press Replay to run the three lanes again and compare the table.
