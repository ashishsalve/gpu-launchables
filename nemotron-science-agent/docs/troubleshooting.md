# Troubleshooting

All commands run in a terminal on the instance.

## The first image pull fails with "connection reset by peer"

Start the services again; the pull resumes:

```
cd /home/ubuntu/workspace && sudo docker compose up -d
```

## The chat page opens but no model is listed

The model is still loading. First start downloads the weights (about 66 GB) and then loads them; the health check allows up to 45 minutes for this. Check progress:

```
cd /home/ubuntu/workspace && sudo docker compose logs --tail 50 vllm
```

## The agent does not answer

```
cd /home/ubuntu/workspace && sudo docker compose ps
cd /home/ubuntu/workspace && sudo docker compose logs --tail 50 hermes
```

Hermes waits for the init service to create its folder and API key file. If `init` exited with an error, run it again:

```
cd /home/ubuntu/workspace && sudo docker compose up init
```

## The LitmusBench check says the dataset is missing

The init service downloads the file on first start and checks its checksum. Re-run `init` as above; if the download keeps failing, set `HF_TOKEN` on a new deploy.

## mdrun fails or is slow

Only one mdrun runs at a time, at most 5000 steps, with a 600 second limit. The model keeps most of the GPU memory; mdrun uses the rest.

## Services are not back after a start

```
cd /home/ubuntu/workspace && sudo docker compose up -d
```

## Deploy log

```
sudo cat /var/log/brev-workspace.log
```
