using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class LookAt : MonoBehaviour
{
    
    [SerializeField]
    private Transform target;

    public Boolean shouldInvert = false;
    [SerializeField]
    private Vector3 rotationOffset = new Vector3(0, 0, 0); // Adjust this in inspector
    
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        if (target == null) return;
        
        Vector3 direction = shouldInvert 
            ? transform.position - target.position 
            : target.position - transform.position;
        
        Quaternion lookRotation = Quaternion.LookRotation(direction, Vector3.up);
        
        // Apply offset
        transform.rotation = lookRotation * Quaternion.Euler(rotationOffset);
    }
}
