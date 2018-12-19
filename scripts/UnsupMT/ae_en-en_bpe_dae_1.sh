gpus=${1:-2}
output=${2:-unsup_debug}
mode=${3:-train}
load_from=${4:-none}  # --load_from name --resume
python -m torch.distributed.launch --nproc_per_node=${gpus} --master_port=23456 \
                ez_run.py \
                --prefix [time] \
                --mode ${mode} \
                --data_prefix "/private/home/jgu/data/" \
                --dataset "wmt16" \
                --src "en" --trg "en" \
                --train_set "train.bpe" \
                --dev_set   "dev.bpe"   \
                --test_set  "test.bpe"  \
                --load_lazy \
                --base "bpe" \
                --workspace_prefix "/private/home/jgu/space/${output}/" \
                --params "t2t-base" \
                --eval_every 500  \
                --batch_size 2048 \
                --inter_size 2 \
                --label_smooth 0.1 \
                --share_embeddings \
                --tensorboard \
                --cross_attn_fashion "forward" \
                --model 'AutoTransformer' \
                --input_noise \
                --load_from ${load_from} \
                
                # --debug --no_valid
                # --variational \

                #--debug
                    #--debug
            

