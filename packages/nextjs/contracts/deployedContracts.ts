/**
 * This file is autogenerated by Scaffold-Stark.
 * You should not edit it manually or your changes might be overwritten.
 */

const deployedContracts = {
  devnet: {
    ExampleExternalContract: {
      address:
        "0x69ed874a997b3dc92e97c2f246fb67cd7492710802b56942765a865de868a5d",
      abi: [
        {
          type: "impl",
          name: "ExampleExternalContractImpl",
          interface_name:
            "contracts::ExampleExternalContract::IExampleExternalContract",
        },
        {
          type: "enum",
          name: "core::bool",
          variants: [
            {
              name: "False",
              type: "()",
            },
            {
              name: "True",
              type: "()",
            },
          ],
        },
        {
          type: "interface",
          name: "contracts::ExampleExternalContract::IExampleExternalContract",
          items: [
            {
              type: "function",
              name: "complete",
              inputs: [],
              outputs: [],
              state_mutability: "external",
            },
            {
              type: "function",
              name: "completed",
              inputs: [],
              outputs: [
                {
                  type: "core::bool",
                },
              ],
              state_mutability: "view",
            },
          ],
        },
        {
          type: "event",
          name: "contracts::ExampleExternalContract::ExampleExternalContract::Event",
          kind: "enum",
          variants: [],
        },
      ],
      classHash:
        "0x69646927cd745e79c8c5b522e4389c630813604b53d87dff6e59c0670288004",
    },
    Staker: {
      address:
        "0x63de2598d7caa1c3cca689aa82dccf597c3633c17bc39588aa6450fc68a6867",
      abi: [
        {
          type: "impl",
          name: "StakerImpl",
          interface_name: "contracts::Staker::IStaker",
        },
        {
          type: "struct",
          name: "core::integer::u256",
          members: [
            {
              name: "low",
              type: "core::integer::u128",
            },
            {
              name: "high",
              type: "core::integer::u128",
            },
          ],
        },
        {
          type: "enum",
          name: "core::bool",
          variants: [
            {
              name: "False",
              type: "()",
            },
            {
              name: "True",
              type: "()",
            },
          ],
        },
        {
          type: "struct",
          name: "openzeppelin_token::erc20::interface::IERC20CamelDispatcher",
          members: [
            {
              name: "contract_address",
              type: "core::starknet::contract_address::ContractAddress",
            },
          ],
        },
        {
          type: "interface",
          name: "contracts::Staker::IStaker",
          items: [
            {
              type: "function",
              name: "execute",
              inputs: [],
              outputs: [],
              state_mutability: "external",
            },
            {
              type: "function",
              name: "stake",
              inputs: [
                {
                  name: "amount",
                  type: "core::integer::u256",
                },
              ],
              outputs: [],
              state_mutability: "external",
            },
            {
              type: "function",
              name: "withdraw",
              inputs: [],
              outputs: [],
              state_mutability: "external",
            },
            {
              type: "function",
              name: "balances",
              inputs: [
                {
                  name: "account",
                  type: "core::starknet::contract_address::ContractAddress",
                },
              ],
              outputs: [
                {
                  type: "core::integer::u256",
                },
              ],
              state_mutability: "view",
            },
            {
              type: "function",
              name: "completed",
              inputs: [],
              outputs: [
                {
                  type: "core::bool",
                },
              ],
              state_mutability: "view",
            },
            {
              type: "function",
              name: "deadline",
              inputs: [],
              outputs: [
                {
                  type: "core::integer::u64",
                },
              ],
              state_mutability: "view",
            },
            {
              type: "function",
              name: "example_external_contract",
              inputs: [],
              outputs: [
                {
                  type: "core::starknet::contract_address::ContractAddress",
                },
              ],
              state_mutability: "view",
            },
            {
              type: "function",
              name: "open_for_withdraw",
              inputs: [],
              outputs: [
                {
                  type: "core::bool",
                },
              ],
              state_mutability: "view",
            },
            {
              type: "function",
              name: "eth_token_dispatcher",
              inputs: [],
              outputs: [
                {
                  type: "openzeppelin_token::erc20::interface::IERC20CamelDispatcher",
                },
              ],
              state_mutability: "view",
            },
            {
              type: "function",
              name: "threshold",
              inputs: [],
              outputs: [
                {
                  type: "core::integer::u256",
                },
              ],
              state_mutability: "view",
            },
            {
              type: "function",
              name: "total_balance",
              inputs: [],
              outputs: [
                {
                  type: "core::integer::u256",
                },
              ],
              state_mutability: "view",
            },
            {
              type: "function",
              name: "time_left",
              inputs: [],
              outputs: [
                {
                  type: "core::integer::u64",
                },
              ],
              state_mutability: "view",
            },
          ],
        },
        {
          type: "constructor",
          name: "constructor",
          inputs: [
            {
              name: "eth_contract",
              type: "core::starknet::contract_address::ContractAddress",
            },
            {
              name: "external_contract_address",
              type: "core::starknet::contract_address::ContractAddress",
            },
          ],
        },
        {
          type: "event",
          name: "contracts::Staker::Staker::Stake",
          kind: "struct",
          members: [
            {
              name: "sender",
              type: "core::starknet::contract_address::ContractAddress",
              kind: "key",
            },
            {
              name: "amount",
              type: "core::integer::u256",
              kind: "data",
            },
          ],
        },
        {
          type: "event",
          name: "contracts::Staker::Staker::Event",
          kind: "enum",
          variants: [
            {
              name: "Stake",
              type: "contracts::Staker::Staker::Stake",
              kind: "nested",
            },
          ],
        },
      ],
      classHash:
        "0x528353c93a6b407415bff6e4405b59755e870c806f8840b55d644105e995875",
    },
  },
} as const;

export default deployedContracts;
