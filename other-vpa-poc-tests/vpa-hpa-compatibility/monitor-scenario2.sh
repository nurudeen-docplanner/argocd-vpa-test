# monitor-scenario2.sh
#!/bin/bash

echo "Timestamp,VPA_Mode,Replicas,Desired_Replicas,Avg_CPU_Usage,Avg_Mem_Usage,CPU_Request,Memory_Request,VPA_Memory_Target,HPA_CPU_Util,Pod_Restarts" > scenario2-monitor.csv

while true; do
  TIMESTAMP=$(date +%H:%M:%S)
  
  # VPA Mode
  VPA_MODE=$(kubectl get vpa vpa-memory-only -o jsonpath='{.spec.updatePolicy.updateMode}' 2>/dev/null || echo "N/A")
  
  # Replica counts
  REPLICAS=$(kubectl get deployment memory-app -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
  DESIRED_REPLICAS=$(kubectl get hpa hpa-cpu-only -o jsonpath='{.status.desiredReplicas}' 2>/dev/null || echo "N/A")
  
  # Actual resource usage
  AVG_CPU=$(kubectl top pods -l app=memory-app --no-headers 2>/dev/null | awk '{gsub(/m/,"",$2); sum+=$2; count++} END {if(count>0) printf "%.0f", sum/count; else print 0}')
  AVG_MEM=$(kubectl top pods -l app=memory-app --no-headers 2>/dev/null | awk '{gsub(/Mi/,"",$3); sum+=$3; count++} END {if(count>0) printf "%.0f", sum/count; else print 0}')
  
  # Current requests (from first pod)
  CPU_REQUEST=$(kubectl get pods -l app=memory-app -o jsonpath='{.items[0].spec.containers[0].resources.requests.cpu}' 2>/dev/null || echo "N/A")
  MEMORY_REQUEST=$(kubectl get pods -l app=memory-app -o jsonpath='{.items[0].spec.containers[0].resources.requests.memory}' 2>/dev/null || echo "N/A")
  
  # VPA recommendation for memory
  VPA_MEMORY=$(kubectl get vpa vpa-memory-only -o jsonpath='{.status.recommendation.containerRecommendations[0].target.memory}' 2>/dev/null || echo "N/A")
  
  # HPA CPU utilization
  HPA_CPU_UTIL=$(kubectl get hpa hpa-cpu-only -o jsonpath='{.status.currentMetrics[0].resource.current.averageUtilization}' 2>/dev/null || echo "N/A")
  
  # Pod restarts
  POD_RESTARTS=$(kubectl get pods -l app=memory-app -o jsonpath='{.items[*].status.containerStatuses[0].restartCount}' 2>/dev/null | awk '{for(i=1;i<=NF;i++) sum+=$i} END {print sum}')
  
  echo "$TIMESTAMP,$VPA_MODE,$REPLICAS,$DESIRED_REPLICAS,$AVG_CPU,$AVG_MEM,$CPU_REQUEST,$MEMORY_REQUEST,$VPA_MEMORY,$HPA_CPU_UTIL,$POD_RESTARTS" | tee -a scenario2-monitor.csv
  
  sleep 10
done
