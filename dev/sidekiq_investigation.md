Sidekiq Snapshot 📸
==================

Sometimes Sidekiq jobs can be stuck exicuting for hours, even days (they stay their until they finish 
or the worker restarts). To help us find out what happened, we have a tool to help us: Kill Signals.

https://github.com/mperham/sidekiq/wiki/Signals

To capture a stacktrace of running sidekiq jobs:

1. Identify job, for example; Process: worker.6:11:e607f5774f73, TID: gpm74dynb
2. Find IP of docker host: (using host #6 as an example)
    - https://console.aws.amazon.com/ecs/home?region=us-east-1#/clusters/prod/services/mpdx_api-production-sidekiq-6-sv2/tasks
    - Tasks tab
    - click task in table
    - click EC2 instance id
    - copy Private IP: 10.16.x.x
3. $ ssh username@10.16.x.x
4. find docker container id: $ sudo docker ps | grep "sidekiq-6"
5. $ sudo docker exec -it {{container id}} bash
6. (Optional) Find number of running tasks: $ ps aux | grep sidekiq
6. $ kill -TTIN PID (PID is in the process id in step one, between the :, 11 in the example I gave)
7. To see your newly minted log: http://logsearch-prod.cru.org/_plugin/kibana/app/kibana#/discover
8. Search by: container:"{{container id from step 4}}"
9. "Toggle Column in Table" for meta_seq_id and message
10. sort by meta_seq_id
11. profit?
