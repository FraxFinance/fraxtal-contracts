<!-- ========== IMPLs ========== -->
<!-- Step 1: Flattening -->
forge flatten --output src/script/Fraxtal/North_Star_Hardfork/L2/flat_files/flattened-wfrax.sol src/contracts/Fraxtal/universal/ERC20ExPPOMWrapped.sol
forge flatten --output src/script/Fraxtal/North_Star_Hardfork/L2/flat_files/flattened-frxeth-l2.sol src/contracts/Fraxtal/universal/ERC20ExWrappedPPOM.sol
forge flatten --output src/script/Fraxtal/North_Star_Hardfork/L2/flat_files/flattened-storagesetterrestricted.sol src/script/Fraxtal/testnet/StorageSetterRestricted.sol
forge flatten --output src/script/Fraxtal/North_Star_Hardfork/L2/flat_files/flattened-l1block.sol src/contracts/Fraxtal/L2/L1BlockCGT.sol
forge flatten --output src/script/Fraxtal/North_Star_Hardfork/L2/flat_files/flattened-l2tol1messagepasser.sol src/contracts/Fraxtal/L2/L2ToL1MessagePasserCGT.sol
forge flatten --output src/script/Fraxtal/North_Star_Hardfork/L2/flat_files/flattened-l2standardbridge.sol src/contracts/Fraxtal/L2/L2StandardBridgeCGT.sol
forge flatten --output src/script/Fraxtal/North_Star_Hardfork/L2/flat_files/flattened-l2crossdomainmessenger.sol src/contracts/Fraxtal/L2/L2CrossDomainMessengerCGT.sol
forge flatten --output src/script/Fraxtal/North_Star_Hardfork/L2/flat_files/flattened-basefeevault.sol src/contracts/Fraxtal/L2/BaseFeeVaultCGT.sol
forge flatten --output src/script/Fraxtal/North_Star_Hardfork/L2/flat_files/flattened-l1feevault.sol src/contracts/Fraxtal/L2/L1FeeVaultCGT.sol
forge flatten --output src/script/Fraxtal/North_Star_Hardfork/L2/flat_files/flattened-sequencerfeevault.sol src/contracts/Fraxtal/L2/SequencerFeeVaultCGT.sol

ADD TEST TOKENS HERE
ADD TEST TOKENS HERE
ADD TEST TOKENS HERE
ADD TEST TOKENS HERE
ADD TEST TOKENS HERE
ADD TEST TOKENS HERE


<!-- Step 2: Cleanup -->
sed -i '/SPDX-License-Identifier/d' src/script/Fraxtal/North_Star_Hardfork/L2/flat_files/flattened-wfrax.sol && sed -i '/pragma solidity/d' src/script/Fraxtal/North_Star_Hardfork/L2/flat_files/flattened-wfrax.sol && sed -i '1s/^/\/\/ SPDX-License-Identifier: GPL-2.0-or-later\npragma solidity >=0.8.0;\n\n/' src/script/Fraxtal/North_Star_Hardfork/L2/flat_files/flattened-wfrax.sol

sed -i '/SPDX-License-Identifier/d' src/script/Fraxtal/North_Star_Hardfork/L2/flat_files/flattened-frxeth-l2.sol && sed -i '/pragma solidity/d' src/script/Fraxtal/North_Star_Hardfork/L2/flat_files/flattened-frxeth-l2.sol && sed -i '1s/^/\/\/ SPDX-License-Identifier: GPL-2.0-or-later\npragma solidity >=0.8.0;\n\n/' src/script/Fraxtal/North_Star_Hardfork/L2/flat_files/flattened-frxeth-l2.sol

sed -i '/SPDX-License-Identifier/d' src/script/Fraxtal/North_Star_Hardfork/L2/flat_files/flattened-storagesetterrestricted.sol && sed -i '/pragma solidity/d' src/script/Fraxtal/North_Star_Hardfork/L2/flat_files/flattened-storagesetterrestricted.sol && sed -i '1s/^/\/\/ SPDX-License-Identifier: GPL-2.0-or-later\npragma solidity >=0.8.0;\n\n/' src/script/Fraxtal/North_Star_Hardfork/L2/flat_files/flattened-storagesetterrestricted.sol

sed -i '/SPDX-License-Identifier/d' src/script/Fraxtal/North_Star_Hardfork/L2/flat_files/flattened-l1block.sol && sed -i '/pragma solidity/d' src/script/Fraxtal/North_Star_Hardfork/L2/flat_files/flattened-l1block.sol && sed -i '1s/^/\/\/ SPDX-License-Identifier: GPL-2.0-or-later\npragma solidity >=0.8.0;\n\n/' src/script/Fraxtal/North_Star_Hardfork/L2/flat_files/flattened-l1block.sol

sed -i '/SPDX-License-Identifier/d' src/script/Fraxtal/North_Star_Hardfork/L2/flat_files/flattened-l2tol1messagepasser.sol && sed -i '/pragma solidity/d' src/script/Fraxtal/North_Star_Hardfork/L2/flat_files/flattened-l2tol1messagepasser.sol && sed -i '1s/^/\/\/ SPDX-License-Identifier: GPL-2.0-or-later\npragma solidity >=0.8.0;\n\n/' src/script/Fraxtal/North_Star_Hardfork/L2/flat_files/flattened-l2tol1messagepasser.sol

sed -i '/SPDX-License-Identifier/d' src/script/Fraxtal/North_Star_Hardfork/L2/flat_files/flattened-l2standardbridge.sol  && sed -i '/pragma solidity/d' src/script/Fraxtal/North_Star_Hardfork/L2/flat_files/flattened-l2standardbridge.sol  && sed -i '1s/^/\/\/ SPDX-License-Identifier: GPL-2.0-or-later\npragma solidity >=0.8.0;\n\n/' src/script/Fraxtal/North_Star_Hardfork/L2/flat_files/flattened-l2standardbridge.sol

sed -i '/SPDX-License-Identifier/d' src/script/Fraxtal/North_Star_Hardfork/L2/flat_files/flattened-l2crossdomainmessenger.sol && sed -i '/pragma solidity/d' src/script/Fraxtal/North_Star_Hardfork/L2/flat_files/flattened-l2crossdomainmessenger.sol && sed -i '1s/^/\/\/ SPDX-License-Identifier: GPL-2.0-or-later\npragma solidity >=0.8.0;\n\n/' src/script/Fraxtal/North_Star_Hardfork/L2/flat_files/flattened-l2crossdomainmessenger.sol

sed -i '/SPDX-License-Identifier/d' src/script/Fraxtal/North_Star_Hardfork/L2/flat_files/flattened-basefeevault.sol && sed -i '/pragma solidity/d' src/script/Fraxtal/North_Star_Hardfork/L2/flat_files/flattened-basefeevault.sol && sed -i '1s/^/\/\/ SPDX-License-Identifier: GPL-2.0-or-later\npragma solidity >=0.8.0;\n\n/' src/script/Fraxtal/North_Star_Hardfork/L2/flat_files/flattened-basefeevault.sol

sed -i '/SPDX-License-Identifier/d' src/script/Fraxtal/North_Star_Hardfork/L2/flat_files/flattened-l1feevault.sol && sed -i '/pragma solidity/d' src/script/Fraxtal/North_Star_Hardfork/L2/flat_files/flattened-l1feevault.sol && sed -i '1s/^/\/\/ SPDX-License-Identifier: GPL-2.0-or-later\npragma solidity >=0.8.0;\n\n/' src/script/Fraxtal/North_Star_Hardfork/L2/flat_files/flattened-l1feevault.sol

sed -i '/SPDX-License-Identifier/d' src/script/Fraxtal/North_Star_Hardfork/L2/flat_files/flattened-sequencerfeevault.sol && sed -i '/pragma solidity/d' src/script/Fraxtal/North_Star_Hardfork/L2/flat_files/flattened-sequencerfeevault.sol && sed -i '1s/^/\/\/ SPDX-License-Identifier: GPL-2.0-or-later\npragma solidity >=0.8.0;\n\n/' src/script/Fraxtal/North_Star_Hardfork/L2/flat_files/flattened-sequencerfeevault.sol


<!-- Step 3: Verification -->
<!-- Manually copy / paste into Fraxscan -->
WFRAX/frxETH_L2: Use 0.8.29, cancun, 1000000
Everything else: Use 0.8.15, london, 1000000

