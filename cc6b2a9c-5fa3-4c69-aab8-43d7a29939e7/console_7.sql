SELECT OSR_INSTANCE_ID, SUB_SYSTEM_ID, LB_SEGMENT_ID, OSR_INSTANCE_DESC, OSR_INSTANCE_FUNCTION.OSR_FUNCTION_NAME, OSR_INSTANCE_FUNCTION.IS_RISK_CHECK_APPLICCABLE
  FROM OSR_INSTANCE_INFO
  INNER JOIN OSR_INSTANCE_FUNCTION ON OSR_INSTANCE_INFO.OSR_FUNCTION_ID = OSR_INSTANCE_FUNCTION.OSR_FUNCTION_ID;


select * from OSR_INSTANCE_FUNCTION