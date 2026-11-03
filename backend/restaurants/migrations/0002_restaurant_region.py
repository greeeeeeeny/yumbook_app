from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("restaurants", "0001_initial"),
    ]

    operations = [
        migrations.AddField(
            model_name="restaurant",
            name="region",
            field=models.CharField(blank=True, db_index=True, max_length=50),
        ),
    ]
