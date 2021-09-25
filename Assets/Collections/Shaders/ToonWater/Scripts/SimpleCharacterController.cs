using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SimpleCharacterController : MonoBehaviour
{
    public float moveSpeed = 5;

    private void Update()
    {
        var hor = Input.GetAxis("Horizontal");
        var ver = Input.GetAxis("Vertical");
        if (hor != 0 || ver != 0)
            Move(hor, ver);
    }

    private void Move(float hor, float ver)
    {
        transform.Translate(moveSpeed * Time.deltaTime * new Vector3(hor, 0, ver));
    }
}