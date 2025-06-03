<!-- ========== IMPLs ========== -->
<!-- Step 1: Flattening -->
forge flatten --output src/script/Fraxtal/North_Star_Hardfork/L1/flat_files/flattened-proxy.sol lib/optimism/packages/contracts-bedrock/src/universal/Proxy.sol
forge flatten --output src/script/Fraxtal/North_Star_Hardfork/L1/flat_files/flattened-l1proxyadmin.sol lib/optimism/packages/contracts-bedrock/src/universal/ProxyAdmin.sol
forge flatten --output src/script/Fraxtal/North_Star_Hardfork/L1/flat_files/flattened-l1storagesetterrestricted.sol src/script/Fraxtal/testnet/StorageSetterRestricted.sol
forge flatten --output src/script/Fraxtal/North_Star_Hardfork/L1/flat_files/flattened-l1crossdomainmessenger.sol src/contracts/Fraxtal/L1/L1CrossDomainMessengerCGT.sol
forge flatten --output src/script/Fraxtal/North_Star_Hardfork/L1/flat_files/flattened-l1erc721bridge.sol lib/optimism/packages/contracts-bedrock/src/L1/L1ERC721Bridge.sol
forge flatten --output src/script/Fraxtal/North_Star_Hardfork/L1/flat_files/flattened-l1standardbridge.sol src/contracts/Fraxtal/L1/L1StandardBridgeCGT.sol
forge flatten --output src/script/Fraxtal/North_Star_Hardfork/L1/flat_files/flattened-optimintableerc20factory.sol lib/optimism/packages/contracts-bedrock/src/universal/OptimismMintableERC20Factory.sol
forge flatten --output src/script/Fraxtal/North_Star_Hardfork/L1/flat_files/flattened-optimismportal.sol src/contracts/Fraxtal/L1/OptimismPortalCGT.sol
forge flatten --output src/script/Fraxtal/North_Star_Hardfork/L1/flat_files/flattened-systemconfig.sol src/contracts/Fraxtal/L1/SystemConfigCGT.sol
forge flatten --output src/script/Fraxtal/North_Star_Hardfork/L1/flat_files/flattened-l1token.sol src/contracts/Fraxtal/universal/vanity/MockERC20OwnedV2.sol
forge flatten --output src/script/Fraxtal/North_Star_Hardfork/L1/flat_files/flattened-badl1token.sol lib/optimism/packages/contracts-bedrock/src/universal/OptimismMintableERC20.sol
forge flatten --output src/script/Fraxtal/North_Star_Hardfork/L1/flat_files/flattened-remotel1token.sol lib/optimism/packages/contracts-bedrock/src/universal/OptimismMintableERC20.sol


<!-- Step 2: Cleanup -->
sed -i '/SPDX-License-Identifier/d' src/script/Fraxtal/North_Star_Hardfork/L1/flat_files/flattened-proxy.sol && sed -i '/pragma solidity/d' src/script/Fraxtal/North_Star_Hardfork/L1/flat_files/flattened-proxy.sol && sed -i '1s/^/\/\/ SPDX-License-Identifier: GPL-2.0-or-later\npragma solidity >=0.8.0;\n\n/' src/script/Fraxtal/North_Star_Hardfork/L1/flat_files/flattened-proxy.sol

sed -i '/SPDX-License-Identifier/d' src/script/Fraxtal/North_Star_Hardfork/L1/flat_files/flattened-l1proxyadmin.sol && sed -i '/pragma solidity/d' src/script/Fraxtal/North_Star_Hardfork/L1/flat_files/flattened-l1proxyadmin.sol && sed -i '1s/^/\/\/ SPDX-License-Identifier: GPL-2.0-or-later\npragma solidity >=0.8.0;\n\n/' src/script/Fraxtal/North_Star_Hardfork/L1/flat_files/flattened-l1proxyadmin.sol

sed -i '/SPDX-License-Identifier/d' src/script/Fraxtal/North_Star_Hardfork/L1/flat_files/flattened-l1storagesetterrestricted.sol && sed -i '/pragma solidity/d' src/script/Fraxtal/North_Star_Hardfork/L1/flat_files/flattened-l1storagesetterrestricted.sol && sed -i '1s/^/\/\/ SPDX-License-Identifier: GPL-2.0-or-later\npragma solidity >=0.8.0;\n\n/' src/script/Fraxtal/North_Star_Hardfork/L1/flat_files/flattened-l1storagesetterrestricted.sol

sed -i '/SPDX-License-Identifier/d' src/script/Fraxtal/North_Star_Hardfork/L1/flat_files/flattened-l1crossdomainmessenger.sol && sed -i '/pragma solidity/d' src/script/Fraxtal/North_Star_Hardfork/L1/flat_files/flattened-l1crossdomainmessenger.sol && sed -i '1s/^/\/\/ SPDX-License-Identifier: GPL-2.0-or-later\npragma solidity >=0.8.0;\n\n/' src/script/Fraxtal/North_Star_Hardfork/L1/flat_files/flattened-l1crossdomainmessenger.sol

sed -i '/SPDX-License-Identifier/d' src/script/Fraxtal/North_Star_Hardfork/L1/flat_files/flattened-l1erc721bridge.sol && sed -i '/pragma solidity/d' src/script/Fraxtal/North_Star_Hardfork/L1/flat_files/flattened-l1erc721bridge.sol && sed -i '1s/^/\/\/ SPDX-License-Identifier: GPL-2.0-or-later\npragma solidity >=0.8.0;\n\n/' src/script/Fraxtal/North_Star_Hardfork/L1/flat_files/flattened-l1erc721bridge.sol

sed -i '/SPDX-License-Identifier/d' src/script/Fraxtal/North_Star_Hardfork/L1/flat_files/flattened-l1standardbridge.sol  && sed -i '/pragma solidity/d' src/script/Fraxtal/North_Star_Hardfork/L1/flat_files/flattened-l1standardbridge.sol  && sed -i '1s/^/\/\/ SPDX-License-Identifier: GPL-2.0-or-later\npragma solidity >=0.8.0;\n\n/' src/script/Fraxtal/North_Star_Hardfork/L1/flat_files/flattened-l1standardbridge.sol 

sed -i '/SPDX-License-Identifier/d' src/script/Fraxtal/North_Star_Hardfork/L1/flat_files/flattened-optimintableerc20factory.sol && sed -i '/pragma solidity/d' src/script/Fraxtal/North_Star_Hardfork/L1/flat_files/flattened-optimintableerc20factory.sol && sed -i '1s/^/\/\/ SPDX-License-Identifier: GPL-2.0-or-later\npragma solidity >=0.8.0;\n\n/' src/script/Fraxtal/North_Star_Hardfork/L1/flat_files/flattened-optimintableerc20factory.sol

sed -i '/SPDX-License-Identifier/d' src/script/Fraxtal/North_Star_Hardfork/L1/flat_files/flattened-optimismportal.sol && sed -i '/pragma solidity/d' src/script/Fraxtal/North_Star_Hardfork/L1/flat_files/flattened-optimismportal.sol && sed -i '1s/^/\/\/ SPDX-License-Identifier: GPL-2.0-or-later\npragma solidity >=0.8.0;\n\n/' src/script/Fraxtal/North_Star_Hardfork/L1/flat_files/flattened-optimismportal.sol

sed -i '/SPDX-License-Identifier/d' src/script/Fraxtal/North_Star_Hardfork/L1/flat_files/flattened-systemconfig.sol && sed -i '/pragma solidity/d' src/script/Fraxtal/North_Star_Hardfork/L1/flat_files/flattened-systemconfig.sol && sed -i '1s/^/\/\/ SPDX-License-Identifier: GPL-2.0-or-later\npragma solidity >=0.8.0;\n\n/' src/script/Fraxtal/North_Star_Hardfork/L1/flat_files/flattened-systemconfig.sol

sed -i '/SPDX-License-Identifier/d' src/script/Fraxtal/North_Star_Hardfork/L1/flat_files/flattened-l1token.sol && sed -i '/pragma solidity/d' src/script/Fraxtal/North_Star_Hardfork/L1/flat_files/flattened-l1token.sol && sed -i '1s/^/\/\/ SPDX-License-Identifier: GPL-2.0-or-later\npragma solidity >=0.8.0;\n\n/' src/script/Fraxtal/North_Star_Hardfork/L1/flat_files/flattened-l1token.sol

sed -i '/SPDX-License-Identifier/d' src/script/Fraxtal/North_Star_Hardfork/L1/flat_files/flattened-badl1token.sol && sed -i '/pragma solidity/d' src/script/Fraxtal/North_Star_Hardfork/L1/flat_files/flattened-badl1token.sol && sed -i '1s/^/\/\/ SPDX-License-Identifier: GPL-2.0-or-later\npragma solidity >=0.8.0;\n\n/' src/script/Fraxtal/North_Star_Hardfork/L1/flat_files/flattened-badl1token.sol

sed -i '/SPDX-License-Identifier/d' src/script/Fraxtal/North_Star_Hardfork/L1/flat_files/flattened-remotel1token.sol && sed -i '/pragma solidity/d' src/script/Fraxtal/North_Star_Hardfork/L1/flat_files/flattened-remotel1token.sol && sed -i '1s/^/\/\/ SPDX-License-Identifier: GPL-2.0-or-later\npragma solidity >=0.8.0;\n\n/' src/script/Fraxtal/North_Star_Hardfork/L1/flat_files/flattened-remotel1token.sol

<!-- Step 3: Verification -->
<!-- Manually copy / paste into Fraxscan -->
<!-- WFRAX/frxETH_L2: Use 0.8.29, cancun, 1000000
Everything else: Use 0.8.15, london, 1000000 -->

