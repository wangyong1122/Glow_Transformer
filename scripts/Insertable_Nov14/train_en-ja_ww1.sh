gpus=${1:-2}
jbname=${2:-Insertable_JA}
mode=${3:-train}
load_from=${4:-none}  # --load_from name --resume
python -m torch.distributed.launch --nproc_per_node=${gpus} --master_port=23456 \
                ez_run.py \
                --prefix ww_opt \
                --mode ${mode} \
                --data_prefix "/private/home/jgu/data/" \
                --dataset "kftt" \
                --src "en" --trg "ja" \
                --train_set "train.sub.shuf.l2r" \
                --dev_set   "dev.sub"  \
                --vocab_file "en-ja/vocab.en-ja.n.ins.pt" \
                --load_lazy \
                --base "bpe" \
                --workspace_prefix "/private/home/jgu/space/${jbname}/" \
                --eval_every 500  \
                --print_every 10 \
                --batch_size 200 \
                --sub_inter_size 1 \
                --inter_size 10 \
                --label_smooth 0.1 \
                --share_embeddings \
                --tensorboard \
                --cross_attn_fashion "forward" \
                --load_from ${load_from} --resume \
                --length_ratio 2 \
                --beam_size 10 \
                --path_temp 1 \
                --relative_pos \
                --model TransformerIww \
                --insertable --insert_mode word_first \
                --order trainable  --beta 12 \
                --no_bound \
                # --debug --no_valid
                
