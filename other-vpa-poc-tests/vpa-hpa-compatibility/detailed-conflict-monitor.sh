#!/bin/bash
# detailed-conflict-monitor.sh

echo "Starting conflict monitoring..."
echo "Timestamp,UpdateMode,Replicas,DesiredReplicas,AvgCPU,AvgMemory,CPURequest,VPA_CPU_Target,MemUtil%,PodRestarts,EventCount" > detailed-conflict.csv

while true; do
  TIMESTAMP=$(date +%Y-%m-%d\ %H:%M:%S)
  
  # VPA Mode
  UPDATE_MODE=$(kubectl get vpa vpa-cpu-only -o jsonpath='{.spec.updatePolicy.updateMode}' 2>/dev/null || echo "N/A")
  
  # Replica counts
  REPLICAS=$(kubectl get deployment memory-app -o jsonpath='{.status.replicas}' 2>/dev/null || echo "0")
  DESIRED_REPLICAS=$(kubectl get hpa hpa-memory-only -o jsonpath='{.status.desiredReplicas}' 2>/dev/null || echo "N/A")
  
  # Resource usage
  AVG_CPU=$(kubectl top pods -l app=memory-app --no-headers 2>/dev/null | awk '{gsub(/m/,"",$2); sum+=$2; count++} END {if(count>0) print sum/count; else print 0}')
  AVG_MEM=$(kubectl top pods -l app=memory-app --no-headers 2>/dev/null | awk '{gsub(/Mi/,"",$3); sum+=$3; count++} END {if(count>0) print sum/count; else print 0}')
  
  # Current CPU request (from first pod)
  CPU_REQUEST=$(kubectl get pods -l app=memory-app -o jsonpath='{.items[0].spec.containers[0].resources.requests.cpu}' 2>/dev/null || echo "N/A")
  
  # VPA recommendation
  VPA_CPU=$(kubectl get vpa vpa-cpu-only -o jsonpath='{.status.recommendation.containerRecommendations[0].target.cpu}' 2>/dev/null || echo "N/A")
  
  # HPA memory utilization
  MEM_UTIL=$(kubectl get hpa hpa-memory-only -o jsonpath='{.status.currentMetrics[0].resource.current.averageUtilization}' 2>/dev/null || echo "N/A")
  
  # Pod restart count
  POD_RESTARTS=$(kubectl get pods -l app=memory-app -o jsonpath='{.items[*].status.containerStatuses[0].restartCount}' 2>/dev/null | awk '{for(i=1;i<=NF;i++) sum+=$i} END {print sum}')
  
  # Recent events count
  EVENT_COUNT=$(kubectl get events --field-selector involvedObject.name=memory-app --sort-by='.lastTimestamp' 2>/dev/null | tail -20 | wc -l)
  
  echo "$TIMESTAMP,$UPDATE_MODE,$REPLICAS,$DESIRED_REPLICAS,$AVG_CPU,$AVG_MEM,$CPU_REQUEST,$VPA_CPU,$MEM_UTIL,$POD_RESTARTS,$EVENT_COUNT" | tee -a detailed-conflict.csv
  
  sleep 10
done
