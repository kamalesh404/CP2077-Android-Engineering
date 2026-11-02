package com.cp2077.companion;

import android.os.Bundle;
import android.widget.Button;
import android.widget.TextView;
import androidx.appcompat.app.AppCompatActivity;

public class MainActivity extends AppCompatActivity {

    private TextView textOutput;
    private Button btnAudit;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        textOutput = findViewById(R.id.textOutput);
        btnAudit = findViewById(R.id.btnAudit);

        btnAudit.setOnClickListener(v -> {
            AuditReport report = DeviceAuditor.runAudit(this);
            textOutput.setText(report.toString());
        });

        // Run initial audit on launch
        AuditReport initialReport = DeviceAuditor.runAudit(this);
        textOutput.setText(initialReport.toString());
    }
}
