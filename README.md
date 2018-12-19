# Neural Machine Translation based on Transformer
<img src="https://github.com/MultiPath/Squirrel/raw/master/sandbox/squarrel.png" alt="GitHub" title="Squirrel" height="365" />

**Major Reference**:

Vaswani, Ashish, et al. "Attention is all you need." 
Advances in Neural Information Processing Systems. 2017.
(http://papers.nips.cc/paper/7181-attention-is-all-you-need)

Popel, Martin, and Ondřej Bojar. "Training Tips for the Transformer Model." 
The Prague Bulletin of Mathematical Linguistics 110.1 (2018): 43-70.
(https://ufal.mff.cuni.cz/pbml/110/art-popel-bojar.pdf)

Gu, Jiatao, Graham Neubig, Kyunghyun Cho, and Victor OK Li. "Learning to translate in real-time with neural machine translation." arXiv preprint arXiv:1610.00388 (2016).

------

**Requirements**: <br>
  Python 3.6  <br>
  PyTorch >= 0.4 <br>
  torchtext >= 0.3 (installed from the source https://github.com/pytorch/text) <br>
  tqdm <br>
  tensorflow-cpu, tensorbaordX <br> (optional) use tensorboard for visualization

------

**Dataset** <br>
We provided the pre-processed (BPE) parallel corpora at <br>
https://www.dropbox.com/sh/p5b6m14is8hd4rn/AAAW5M6ddaiwjd5DbugNPmdEa?dl=0

You can simply download all the datasets and put them to your <DATA_DIR>.<br>
currently included <br>

WMT16 RO-EN (600K) <br>
WMT14 EN-DE (4.5M) <br>

------

**Pre-processing** <br>
```shell
python ez_run.py \
                --prefix [time]  \
                --mode data \
                --data_prefix <DATA_DIR> \
                --dataset "wmt16" \
                --src "ro" \
                --trg "en" \
                --train_set "train.bpe" \
                --dev_set   "dev.bpe"   \
                --char # (optional) if use, build the character-level vocabulary.
```

------

**Training** <br>
train the NMT model with basic Transformer <br>
Due to pytorch limitation, the multi-GPU version is still under constration.
In order to achieve large batch size on single GPU, we used a trick to perform multiple passes (--inter_size) before one update to the parametrs which, however, hurts the training efficiency.

```shell
python ez_run.py \
                --prefix [time]  \
                --gpu  <GPU_ID> \
                --mode train \
                --data_prefix <DATA_DIR> \
                --dataset "wmt16" \
                --src "ro" \
                --trg "en" \
                --train_set "train.bpe" \
                --dev_set   "dev.bpe"   \
                --load_lazy  \         # (recommended) suitable for Large corpus. Pre-shuffling the dataset is required.
                --workspace_prefix <MODEL_DIR> \  # where you save models, states, and logs.
                --params "t2t-base" \  # d_model=512, d_ff=2048, n_h=8, n_l=6, warmup=16,000
                --eval_every 500 \
                --batch_size 1200 \    # the actual batch-size=1200*3=3600, for validation, it is batch_size x 4 in default.
                --inter_size 3 \      
                --label_smooth 0.1 \   # (optional) if > 0.1, use label-smoothing when training
                --share_embeddings \   # (optional) if use, source and target share the same vocabulary.
                --char \               # (optional) if use, train the character-level instead of bpe-level. 
                --causal_enc \         # (optional) if use, encoder uses causal attention (unidirectional)
                --encoder_lm \         # (optional) if use, additional LM loss over encoder (requires "--causal_enc")
                --cross_attn_fashion "forward" \ # (optional) ["forward", "reverse", "last_layer"], in default "forward", 
                --tensorboard \
                --debug                # (optional) if use, no saving tensorboard.
```

The code will automatically record in <MODEL_DIR> respectively in: 
```
<MODEL_DIR>/logs/log-[time].txt      #detailed logs, easy to check the parameter settings.
<MODEL_DIR>/models/<MODEL_NAME>.pt   #models and running states. Automatically save the best model achieved highest score on the dev-set.
<MODEL_DIR>/runs/<MODEL_NAME>        #tensorboard data used for visualization. Only works when --debug is not used.
```

**Use Tensorboard** <br>
Make sure to install *tensorflow* and *tensorboardX* first.

Make sure not to use --debug argument.

```shell
tensorboard --logdir=<MODEL_DIR>/runs --port=<YOUR_PORT>
```
Please see the following examples for the experiments of WMT En-De:

<img src="https://github.com/MultiPath/Squirrel/raw/master/sandbox/tensorboard_example.jpeg" alt="GitHub" title="Tensorboard" height="365" />


------

**Decoding** <br>
decode from the pretrained NMT model. In default, decode from the dev set using beam-search (beam size=5, alpha=0.6). <br>
please check the saved the log to make sure the testing model has the same options as training.

```shell
python ez_run.py \
                --prefix [time]  \
                --gpu  <GPU_ID> \
                --mode test \
                --data_prefix <DATA_DIR> \
                --dataset "wmt16" \
                --src "ro" \
                --trg "en" \
                --test_set  "test.bpe"  \
                --workspace_prefix <MODEL_DIR> \  # where you save models, states, and logs.
                --load_from <MODEL_PATH>  # pretrained model
                --params "t2t-base" \  # d_model=512, d_ff=2048, n_h=8, n_l=6, warmup=16000
                --batch_size 1250 \    # in default we use batch_size x 8 as the actual batch-size.
                --beam 5 \
                --alpha 0.6 \          # hyper-parameter for length-penalty
                --share_embeddings \   # (optional) if use, source and target share the same vocabulary.
                --char \               # (optional) if use, train the character-level instead of bpe-level. 
                --causal_enc \         # (optional) if use, encoder uses causal attention (unidirectional)
                --encoder_lm \         # (optional) if use, additional LM loss over encoder (requires "--causal_enc")
                --cross_attn_fashion "forward" \ # (optional) ["forward", "reverse", "last_layer"], in default "forward", 
```

Some ablation studies of different models can be found as follows. <br>
For all cases, beam search uses beam_size=5, alpha=0.6. <br>
(1) For Ro-En experiments, we found that the label smoothing is quite important for Transformer.
    We also try a model with causal encoder (with additional source side language model loss) which can achieve very close performance compared to a full attention model. 

| WMT16 Ro-En | base, ls=0 | base, ls=0.1 |  casual, ls=0.1 | casual + lm, ls=0.1 |
| :--- | :----: | :----: | :----: | :----: |
| (dev) greedy | 32.82 | 34.16 | 33.26 | 33.78 |
| (dev) beam search   | 33.39 |  34.73  | 33.74 | 33.95 |
| (test) greedy | 31.51 | 32.68 | 31.70 | 32.49 |
| (test) beam search  | 31.94 |  **33.00**  | 32.12 | 32.73 |

<!-- We also have an interesting comparison with different cross-attention fashion for Ro-En. In the typical Transformer model (assuming n_layers=6), <br>
"forward": decoder layer l attends to encoder layer l <br>
"reverse": decoder layer l attends to encoder layer 6 - l <br>
"last_layer": decoder layer always attends to encoder layer 6 (suggested in the original (Vaswani et. al, 2017))

| WMT16 Ro-En | forward| reverse | last_layer |
| :--- | :----: | :----: | :----: |
| (dev) greedy | 32.68 | crashed |  |
| (dev) beam search   | **33.00** |  crashed    | |

Based on our observation, in the our implementation, "forward" attention works better than the default version, and "reverse" attention will crash before converge. -->

(2) For En-De, which is relavitely more challenging compared to Ro-En. Following (Vaswani et. al, 2017), we valid the model based on newstest2013, and test on newstest2014.

 We argue that the batch_size is an important hyper-parameter for such large dataset. Since our code is currently not supporting multi-GPU training yet, large batch size is obtained by running multiple steps (for 15,000, we use batch_size=1500, inter_size=10) before updating the parameters. We also show the original performance noted in the Transformer paper, where the model used a batch size of 25,000, together with model-averaging.

| WMT14 En-De | bs = 5000 | bs = 15000 | (Vaswani et. al, 2017)
| :--- | :----: | :----: | :----: | 
| (newstest2013) greedy   | 23.11 |  24.95 | - | 
| (newstest2013) beam=5   | 23.62 |  25.14 | 25.8 |
| (newstest2014) greedy           | 22.62 |  24.92 |  - |  
| (newstest2014) beam=5           | 23.71 |  25.97 | 27.3 |

# TODO
  Add more description about data processing/training/testing