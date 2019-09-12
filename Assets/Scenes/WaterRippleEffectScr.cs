using System.Collections;
using System.Collections.Generic;
using UnityEngine;


public class WaterRippleEffectScr : MonoBehaviour
{
    public float WaveSpeed;
    public uint RippleCount;
    public float RippleGap = 10f;
    [Range(0, 0.5f)]
    public float RippleMaxWidth = 0.4f;
    [Range(0, 1f)]
    public float RippleDeffered = 0.5f;

    private float[] _waveStartTime;
    private float[] _waveCurDis;
    private Material _mat;

    private void OnEnable()
    {
        if (!_mat)
        {
            _mat = GetComponent<Renderer>().sharedMaterial;
            _waveStartTime = new float[RippleCount * RippleCount];
            _waveCurDis = new float[RippleCount * RippleCount];
        }
    }

    private void OnWillRenderObject()
    {
        uint ripplePow = RippleCount * RippleCount;
        if (ripplePow != _waveStartTime.Length)
        {
            _waveStartTime = new float[RippleCount * RippleCount];
            _waveCurDis = new float[RippleCount * RippleCount];
        }
        for (int i = 0; i < ripplePow; i++)
        {
            float startTime = _waveStartTime[i];
            float curDis = 0;
            if (startTime <= 0)
            {
                _waveStartTime[i] = startTime = Time.time + Random.Range(0, RippleGap);
                curDis = 1f;
            }
            else
            {
                curDis = (Time.time - startTime) * WaveSpeed;              
                if (curDis* RippleDeffered >= RippleMaxWidth)
                {
                    _waveStartTime[i] = Time.time + Random.Range(0, RippleGap);
                }
                curDis = curDis < 0 ? 1f : curDis;
            }          
            _waveCurDis[i] = curDis;            
        }
        _mat.SetFloatArray("_CurRipples", _waveCurDis);
        _mat.SetFloat("_Size", RippleCount);
        _mat.SetFloat("_RippleWidth", RippleMaxWidth);
    }
}
