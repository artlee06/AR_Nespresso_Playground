using System.Collections;
using System.Collections.Generic;
using UnityEngine;


// using PrimeTween;
// Take reference from the XR origin point -> likely the stationary guardian where you're sitting
// Don't need to follow and stick -> either delayed follow all the way OR just initialise it somewhere then let the user move it with their hands etc
// Use the launch coordinates as the initial point then let the user use the center gesture. 

namespace Meta.XR.MRUtilityKit
{
    public class InitialiseOriginCamera : MonoBehaviour
    {
        
        public Vector3 offset = new Vector3(0f, 0f, 1.0f);        
        
        [SerializeField]
        private Transform target; // centerEyeAnchor

        private bool hasPositioned = false;
        
        // Start is called before the first frame update
        void Start()
        {
            if (target == null)
            {
                Debug.LogError("Target (centerEyeAnchor) is not set in FollowCamera script.");
                return;
            }

            // Subscribe to the recenter event
            OVRManager.display.RecenteredPose += OnRecenteredPose;
        }

        void OnDestroy()
        {
            // Unsubscribe from the event when the script is destroyed
            if (OVRManager.display != null)
            {
                OVRManager.display.RecenteredPose -= OnRecenteredPose;
            }
        }

        void LateUpdate()
        {
            if (!hasPositioned)
            {
                PositionRelativeToCamera();
                hasPositioned = true;
            }
        }

        void OnRecenteredPose()
        {
            // Reposition when the user recenters their view
            PositionRelativeToCamera();
        }

        void PositionRelativeToCamera()
        {
            Vector3 forward = Vector3.ProjectOnPlane(target.forward, Vector3.up).normalized;
            Vector3 right = Vector3.Cross(Vector3.up, forward).normalized;
            
            // Position the object in front of the camera
            Vector3 targetPos = target.position + (forward * offset.z) + (right * offset.x) + (Vector3.up * offset.y);

            transform.position = targetPos;
            // Rotate to face the camera
            transform.rotation = Quaternion.LookRotation(-forward, Vector3.up);

            Debug.Log($"Camera position: {target.position}, Object position: {transform.position}");
            
        }

    }

}
