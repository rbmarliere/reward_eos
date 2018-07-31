#!/bin/sh

reward_eos()
{
    rm -rf history.csv

    account=${1:-eosswedenorg}

    current_page=$(cleos get actions -j ${account})

    while true; do
        first_seq=$(echo ${current_page} | jq '.actions[0].account_action_seq')
        last_seq=$(echo ${current_page} | jq '.actions[-1].account_action_seq')
        page_size=$(( ${last_seq} - ${first_seq} ))
        #echo page_size=${last_seq} - ${first_seq}=${page_size}

        page_pays=$(echo ${current_page} | jq '[.actions[]|{block_time:.block_time,pay:(.action_trace.inline_traces[].act.data|select((.from=="eosio.bpay")or(.from=="eosio.vpay"))|.quantity|rtrimstr(" EOS")|tonumber*10000)}]' | jq 'group_by(.block_time)|map([.[0].block_time,(map(.pay)|add/10000)])|reverse' | jq -r '.[]|@csv')
        echo ${page_pays} >> history.csv

        next_seq=$(( ${first_seq} - ${page_size} - 1 ))
        if [ ${next_seq} -lt 0 ]; then
            next_seq=0
            page_size=$(( ${first_seq} - 1 ))
        fi
        if [ ${page_size} -lt 0 ]; then
            break
        fi
        current_page=$(cleos get actions -j ${account} ${next_seq} ${page_size})

        #echo cleos get actions ${account} ${next_seq} ${page_size}
    done
}

