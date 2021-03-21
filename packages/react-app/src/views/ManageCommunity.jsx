/* eslint-disable jsx-a11y/accessible-emoji */

import React, { useState } from "react";
import { Button, List, Divider, Input, Card, DatePicker, Slider, Switch, Progress, Spin } from "antd";
import { SyncOutlined } from '@ant-design/icons';
import { Address, Balance } from "../components";
import { parseEther, formatEther } from "@ethersproject/units";
import { namehash } from '@ensdomains/ensjs';
import { useContractReader } from '../hooks'

export default function ManageCommunity({
  domain,
  mainnetProvider, userProvider, localProvider,
  yourLocalBalance, price,
  tx, readContracts, writeContracts
}) {
  const members = useContractReader(readContracts, "CommunityManager", 'getMembersByRole', [
    useContractReader(readContracts, "CommunityManager", 'MEMBER_ROLE')
  ])
  return (
    <div>
      

    </div>
  )
}
