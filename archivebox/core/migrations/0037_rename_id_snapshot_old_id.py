# Generated by Django 5.0.6 on 2024-08-18 06:08

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0036_alter_archiveresult_id_alter_archiveresult_old_id'),
    ]

    operations = [
        migrations.RenameField(
            model_name='snapshot',
            old_name='id',
            new_name='old_id',
        ),
    ]
